defmodule Duffel.Client do
  @moduledoc """
  HTTP transport for the Duffel API.

  Handles authentication, required headers, the `data` request/response
  envelope, error normalisation and cursor pagination. Resource modules
  (e.g. `Duffel.OfferRequests`) build on top of this module; most
  applications won't need to call it directly.

  ## Errors

  A failed request always comes back as `{:error, %Duffel.Error{}}`. That
  covers requests the API rejected and requests that never reached it: a
  connection or timeout failure becomes an error with `type:
  :transport_error` and the original exception under `:reason`.

  ## Timeouts

  A request waits 130 seconds for a response before giving up. Duffel
  allows order and booking creation to take up to 120 seconds, and
  recommends a client timeout slightly above that. Searches are quicker:
  each airline gets 20 seconds to answer by default, up to the 60 seconds
  `supplier_timeout` allows. Lower `:receive_timeout` on a client used
  only for searching:

      Duffel.new(access_token: token, receive_timeout: 30_000)

  A timeout is a transient failure, so it is retried like any other.

  ## Retries and idempotency

  A failed request is retried up to three times with a growing delay, but
  only when Duffel calls the failure retryable: a 408, 429 or 503, or a
  network error. Duffel documents 500 and 502 as "you should not retry
  this request", so neither is. A 504 can mean the supplier processed the
  request after all, so it is retried for `GET` and `HEAD` only, never for
  a `POST` that could book twice.

  Retries still apply to every method, so each `POST` also carries an
  `Idempotency-Key` header. Duffel's API documentation never mentions
  idempotency keys, so treat the header as a precaution rather than a
  promise that a repeated `POST` is discarded — what stops a retry booking
  twice is the policy above. See `post/4` for how to supply your own key.

  Pass your own `retry:` in `:req_options` to replace this policy.

  ## Telemetry

  Every request emits a [`telemetry`](https://hexdocs.pm/telemetry) span
  under the `[:duffel, :request]` prefix:

    * `[:duffel, :request, :start]` - measurements `%{system_time, monotonic_time}`
    * `[:duffel, :request, :stop]` - measurements `%{duration, monotonic_time}`
    * `[:duffel, :request, :exception]` - when the request function raises

  Metadata on every event: `:method`, `:path` and `:base_url`. The `:stop`
  event also carries `:status` (the HTTP status, or `nil` on a transport
  error), `:result` (`:ok` or `:error`) and `:rate_limit` (a
  `Duffel.RateLimit`, or `nil` when the response reported none).

  Attach a handler to measure request latency:

      :telemetry.attach(
        "duffel-logger",
        [:duffel, :request, :stop],
        fn _event, %{duration: duration}, meta, _config ->
          ms = System.convert_time_unit(duration, :native, :millisecond)
          Logger.info("duffel \#{meta.method} \#{meta.path} -> \#{meta.status} (\#{ms}ms)")
        end,
        nil
      )

  """

  alias Duffel.{Error, Page, RateLimit}

  @base_url "https://api.duffel.com"
  @cards_base_url "https://api.duffel.cards"
  @api_version "v2"

  # Req waits 15s by default, which is less than the 20s Duffel gives each
  # airline to answer a search, so a plain offer request could not finish.
  @receive_timeout 130_000

  # The client is passed to every resource function, so it shows up in stack
  # traces, crash reports and error trackers. Keep the token out of them.
  @derive {Inspect, except: [:access_token]}
  defstruct access_token: nil,
            base_url: @base_url,
            cards_base_url: @cards_base_url,
            api_version: @api_version,
            receive_timeout: @receive_timeout,
            req_options: []

  @type t :: %__MODULE__{
          access_token: String.t(),
          base_url: String.t(),
          cards_base_url: String.t(),
          api_version: String.t(),
          receive_timeout: timeout(),
          req_options: keyword()
        }

  @type response :: {:ok, map()} | {:error, Error.t()}

  @doc """
  Builds a client struct.

  Raises `ArgumentError` if `:access_token` is missing.

  The token is hidden when the struct is inspected, so it does not reach
  logs or error trackers. Read `client.access_token` to get it back.

  ## Examples

      iex> client = Duffel.new(access_token: "duffel_test_abc")
      iex> inspect(client) =~ "duffel_test_abc"
      false

  """
  @spec new(keyword()) :: t()
  def new(opts) when is_list(opts) do
    access_token =
      Keyword.get(opts, :access_token) ||
        raise ArgumentError,
              "missing :access_token. Pass it to Duffel.new/1 or set it in " <>
                "the :duffel application environment."

    %__MODULE__{
      access_token: access_token,
      base_url: Keyword.get(opts, :base_url, @base_url),
      cards_base_url: Keyword.get(opts, :cards_base_url, @cards_base_url),
      api_version: Keyword.get(opts, :api_version, @api_version),
      receive_timeout: Keyword.get(opts, :receive_timeout, @receive_timeout),
      req_options: Keyword.get(opts, :req_options, [])
    }
  end

  @doc """
  Performs a `GET` request.

  ## Options

    * `:params` - query string parameters. A list value is sent as one
      parameter per element, which is how Duffel's `key[]` array filters
      work: `params: %{"passenger_name[]" => ["Amelia", "Earhart"]}` sends
      `passenger_name[]=Amelia&passenger_name[]=Earhart`.

  """
  @spec get(t(), String.t(), keyword()) :: response()
  def get(%__MODULE__{} = client, path, opts \\ []) do
    request(client, :get, path, opts)
  end

  @doc """
  Performs a `POST` request, wrapping `body` in the `data` envelope the
  Duffel API expects.

  Every `POST` carries an `Idempotency-Key` header. One is generated
  unless you pass your own. Pass `idempotency_key: nil` to send no key at
  all.

  Duffel's API documentation does not describe how it treats this header,
  so do not count on it to collapse two identical bookings. Supply your
  own key when the caller may retry the same logical operation across
  processes or deploys, and check whether the resource already exists
  before retrying a create yourself.

  ## Options

    * `:params` - query string parameters
    * `:idempotency_key` - value for the `Idempotency-Key` header. Defaults
      to a generated key; `nil` sends no header.

  """
  @spec post(t(), String.t(), map(), keyword()) :: response()
  def post(%__MODULE__{} = client, path, body, opts \\ []) do
    opts =
      opts
      |> Keyword.put_new_lazy(:idempotency_key, &generate_idempotency_key/0)
      |> Keyword.put(:json, %{data: body})

    request(client, :post, path, opts)
  end

  @doc """
  Performs a `PATCH` request, wrapping `body` in the `data` envelope.
  """
  @spec patch(t(), String.t(), map(), keyword()) :: response()
  def patch(%__MODULE__{} = client, path, body, opts \\ []) do
    request(client, :patch, path, Keyword.put(opts, :json, %{data: body}))
  end

  @doc """
  Performs a `PUT` request, wrapping `body` in the `data` envelope.
  """
  @spec put(t(), String.t(), map(), keyword()) :: response()
  def put(%__MODULE__{} = client, path, body, opts \\ []) do
    request(client, :put, path, Keyword.put(opts, :json, %{data: body}))
  end

  @doc """
  Performs a `DELETE` request.
  """
  @spec delete(t(), String.t(), keyword()) :: response()
  def delete(%__MODULE__{} = client, path, opts \\ []) do
    request(client, :delete, path, opts)
  end

  @doc """
  Takes the resource out of the `data` envelope Duffel wraps it in.

  A success response with no `data` key becomes an `:unexpected_response`
  error rather than being handed back as if the envelope were the
  resource. Errors pass through untouched.

  `get_data/3`, `post_data/4`, `patch_data/4` and `put_data/4` do this for
  you; reach for `unwrap/1` directly only when you have built the request
  some other way.

  ## Examples

      client |> get("/air/orders/ord_123") |> unwrap()
      #=> {:ok, %{"id" => "ord_123", ...}}

  """
  @spec unwrap(response()) :: {:ok, term()} | {:error, Error.t()}
  def unwrap({:ok, %{"data" => data}}), do: {:ok, data}
  def unwrap({:ok, body}), do: {:error, Error.unexpected_response(body)}
  def unwrap({:error, %Error{}} = error), do: error

  @doc """
  Throws away the response body, reporting only whether the request
  succeeded.

  For endpoints that return nothing useful, such as a delete or an action
  that just acknowledges. Errors pass through untouched.

  ## Examples

      client |> delete("/air/webhooks/sev_123") |> discard()
      #=> :ok

  """
  @spec discard(response()) :: :ok | {:error, Error.t()}
  def discard({:ok, _body}), do: :ok
  def discard({:error, %Error{}} = error), do: error

  @doc """
  Performs a `GET` request and unwraps the resource from the `data`
  envelope. See `get/3` and `unwrap/1`.
  """
  @spec get_data(t(), String.t(), keyword()) :: {:ok, term()} | {:error, Error.t()}
  def get_data(%__MODULE__{} = client, path, opts \\ []) do
    client |> get(path, opts) |> unwrap()
  end

  @doc """
  Performs a `POST` request and unwraps the resource from the `data`
  envelope. See `post/4` and `unwrap/1`.
  """
  @spec post_data(t(), String.t(), map(), keyword()) :: {:ok, term()} | {:error, Error.t()}
  def post_data(%__MODULE__{} = client, path, body, opts \\ []) do
    client |> post(path, body, opts) |> unwrap()
  end

  @doc """
  Performs a `PATCH` request and unwraps the resource from the `data`
  envelope. See `patch/4` and `unwrap/1`.
  """
  @spec patch_data(t(), String.t(), map(), keyword()) :: {:ok, term()} | {:error, Error.t()}
  def patch_data(%__MODULE__{} = client, path, body, opts \\ []) do
    client |> patch(path, body, opts) |> unwrap()
  end

  @doc """
  Performs a `PUT` request and unwraps the resource from the `data`
  envelope. See `put/4` and `unwrap/1`.
  """
  @spec put_data(t(), String.t(), map(), keyword()) :: {:ok, term()} | {:error, Error.t()}
  def put_data(%__MODULE__{} = client, path, body, opts \\ []) do
    client |> put(path, body, opts) |> unwrap()
  end

  @doc """
  Performs a `GET` request against a list endpoint and wraps the result
  in a `Duffel.Page`.

  Like `unwrap/1`, a success response whose `data` is missing or is not a
  list is an `:unexpected_response` error rather than an empty page.
  """
  @spec list(t(), String.t(), keyword() | map()) :: {:ok, Page.t()} | {:error, Error.t()}
  def list(%__MODULE__{} = client, path, params \\ []) do
    case get(client, path, params: Map.new(params)) do
      {:ok, %{"data" => data} = body} when is_list(data) -> {:ok, Page.from_body(body)}
      {:ok, body} -> {:error, Error.unexpected_response(body)}
      {:error, %Error{}} = error -> error
    end
  end

  @doc """
  Lazily streams every item from a paginated list endpoint, following
  `meta.after` cursors until exhausted.

  Raises `Duffel.Error` if any page request fails, or if Duffel hands back
  the cursor it was just given, which would otherwise fetch the same page
  forever.
  """
  @spec stream(t(), String.t(), keyword() | map()) :: Enumerable.t()
  def stream(%__MODULE__{} = client, path, params \\ []) do
    # Keys are normalised so the cursor added below replaces a caller's own
    # `after` rather than being sent alongside it.
    params = Map.new(params, fn {key, value} -> {to_string(key), value} end)

    Stream.resource(
      fn -> {:page, params} end,
      fn
        :done ->
          {:halt, :done}

        {:page, params} ->
          case list(client, path, params) do
            {:ok, %Page{data: data, after_cursor: nil}} ->
              {data, :done}

            {:ok, %Page{data: data, after_cursor: cursor}} ->
              {data, {:page, advance(params, cursor)}}

            {:error, %Error{} = error} ->
              raise error
          end
      end,
      fn _ -> :ok end
    )
  end

  @doc false
  @spec request(t(), atom(), String.t(), keyword()) :: response()
  def request(%__MODULE__{} = client, method, path, opts \\ []) do
    {idempotency_key, opts} = Keyword.pop(opts, :idempotency_key)
    {params, opts} = Keyword.pop(opts, :params)
    base_url = Keyword.get(opts, :base_url, client.base_url)
    url = append_query(path, params)

    headers =
      [{"duffel-version", client.api_version}, {"accept", "application/json"}] ++
        if idempotency_key, do: [{"idempotency-key", idempotency_key}], else: []

    req_options =
      [
        method: method,
        base_url: base_url,
        url: url,
        auth: {:bearer, client.access_token},
        headers: headers,
        compressed: true,
        receive_timeout: client.receive_timeout,
        retry: &retry?/2
      ]
      |> Keyword.merge(Keyword.take(opts, [:json]))
      |> Keyword.merge(client.req_options)

    metadata = %{method: method, path: path, base_url: base_url}

    :telemetry.span([:duffel, :request], metadata, fn ->
      response = Req.request(req_options)
      result = handle_response(response)

      stop_metadata =
        Map.merge(metadata, %{
          status: response_status(response),
          result: result_tag(result),
          rate_limit: response_rate_limit(response)
        })

      {result, stop_metadata}
    end)
  end

  # Handing back the cursor we just sent would fetch the same page again, and
  # again. Stop loudly rather than spin.
  defp advance(%{"after" => cursor} = _params, cursor) do
    raise %Error{
      type: :unexpected_response,
      title: "Pagination stalled",
      message:
        "Duffel returned the same `after` cursor twice (#{inspect(cursor)}), " <>
          "so the next page would repeat this one"
    }
  end

  defp advance(params, cursor), do: Map.put(params, "after", cursor)

  # Duffel documents 500 and 502 as not retryable, so a failing order create
  # is handed back rather than sent again. 504 may mean the supplier processed
  # the request, so only safe methods retry it.
  @retry_statuses [408, 429, 503]
  @safe_retry_statuses [504]
  @retry_transport_reasons [:timeout, :econnrefused, :closed]
  @retry_http2_reasons [:unprocessed, :pool_not_available]

  @doc false
  @spec retry?(Req.Request.t(), Req.Response.t() | Exception.t()) :: boolean()
  def retry?(request, response_or_exception)

  def retry?(_request, %Req.Response{status: status}) when status in @retry_statuses, do: true

  def retry?(%Req.Request{method: method}, %Req.Response{status: status})
      when status in @safe_retry_statuses and method in [:get, :head],
      do: true

  def retry?(_request, %Req.TransportError{reason: reason})
      when reason in @retry_transport_reasons,
      do: true

  def retry?(_request, %Req.HTTPError{protocol: :http2, reason: reason})
      when reason in @retry_http2_reasons,
      do: true

  def retry?(_request, _response_or_exception), do: false

  # Duffel takes repeated `key[]` parameters for array filters, and
  # `key[sub]` for its datetime range filters. Req's `:params` option cannot
  # express either: it keeps only the last value for a repeated key, and
  # renders a list or map value as one run-together string. So the query
  # string is built here and appended to the path.
  defp append_query(path, nil), do: path

  defp append_query(path, params) do
    case encode_query(params) do
      "" -> path
      query -> path <> if(String.contains?(path, "?"), do: "&", else: "?") <> query
    end
  end

  defp encode_query(params) do
    params
    |> Enum.flat_map(&encode_param/1)
    |> URI.encode_query()
  end

  # A list sends one parameter per element, so `passenger_name[]` can carry
  # several names. A map nests, so `departing_at: %{after: ...}` becomes
  # `departing_at[after]=...`.
  defp encode_param({key, values}) when is_list(values) do
    Enum.map(values, &{to_string(key), &1})
  end

  defp encode_param({key, nested}) when is_map(nested) and not is_struct(nested) do
    Enum.flat_map(nested, fn {sub_key, value} ->
      encode_param({"#{key}[#{sub_key}]", value})
    end)
  end

  defp encode_param({key, value}), do: [{to_string(key), value}]

  # Failed requests are retried automatically, including POSTs, so every POST
  # gets a key to stop a retry booking twice.
  defp generate_idempotency_key do
    24 |> :crypto.strong_rand_bytes() |> Base.url_encode64(padding: false)
  end

  defp response_status({:ok, %Req.Response{status: status}}), do: status
  defp response_status(_other), do: nil

  defp response_rate_limit({:ok, %Req.Response{} = response}),
    do: RateLimit.from_response(response)

  defp response_rate_limit(_other), do: nil

  defp result_tag({:ok, _body}), do: :ok
  defp result_tag({:error, _reason}), do: :error

  defp handle_response({:ok, %Req.Response{status: status, body: body}})
       when status in 200..299 do
    {:ok, body}
  end

  defp handle_response({:ok, %Req.Response{} = response}) do
    {:error, Error.from_response(response)}
  end

  defp handle_response({:error, exception}) do
    {:error, Error.from_exception(exception)}
  end
end
