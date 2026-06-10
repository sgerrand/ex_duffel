defmodule Duffel.Client do
  @moduledoc """
  HTTP transport for the Duffel API.

  Handles authentication, required headers, the `data` request/response
  envelope, error normalisation and cursor pagination. Resource modules
  (e.g. `Duffel.OfferRequests`) build on top of this module; most
  applications won't need to call it directly.

  ## Telemetry

  Every request emits a [`telemetry`](https://hexdocs.pm/telemetry) span
  under the `[:duffel, :request]` prefix:

    * `[:duffel, :request, :start]` - measurements `%{system_time, monotonic_time}`
    * `[:duffel, :request, :stop]` - measurements `%{duration, monotonic_time}`
    * `[:duffel, :request, :exception]` - when the request function raises

  Metadata on every event: `:method`, `:path` and `:base_url`. The `:stop`
  event also carries `:status` (the HTTP status, or `nil` on a transport
  error) and `:result` (`:ok` or `:error`).

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

  alias Duffel.{Error, Page}

  @base_url "https://api.duffel.com"
  @cards_base_url "https://api.duffel.cards"
  @api_version "v2"

  defstruct access_token: nil,
            base_url: @base_url,
            cards_base_url: @cards_base_url,
            api_version: @api_version,
            req_options: []

  @type t :: %__MODULE__{
          access_token: String.t(),
          base_url: String.t(),
          cards_base_url: String.t(),
          api_version: String.t(),
          req_options: keyword()
        }

  @type response :: {:ok, map()} | {:error, Error.t() | Exception.t()}

  @doc """
  Builds a client struct.

  Raises `ArgumentError` if `:access_token` is missing.
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
      req_options: Keyword.get(opts, :req_options, [])
    }
  end

  @doc """
  Performs a `GET` request.

  ## Options

    * `:params` - query string parameters

  """
  @spec get(t(), String.t(), keyword()) :: response()
  def get(%__MODULE__{} = client, path, opts \\ []) do
    request(client, :get, path, opts)
  end

  @doc """
  Performs a `POST` request, wrapping `body` in the `data` envelope the
  Duffel API expects.

  ## Options

    * `:params` - query string parameters
    * `:idempotency_key` - sets the `Idempotency-Key` header

  """
  @spec post(t(), String.t(), map(), keyword()) :: response()
  def post(%__MODULE__{} = client, path, body, opts \\ []) do
    request(client, :post, path, Keyword.put(opts, :json, %{data: body}))
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
  Performs a `GET` request against a list endpoint and wraps the result
  in a `Duffel.Page`.
  """
  @spec list(t(), String.t(), keyword() | map()) :: {:ok, Page.t()} | {:error, term()}
  def list(%__MODULE__{} = client, path, params \\ []) do
    with {:ok, body} <- get(client, path, params: Map.new(params)) do
      {:ok, Page.from_body(body)}
    end
  end

  @doc """
  Lazily streams every item from a paginated list endpoint, following
  `meta.after` cursors until exhausted.

  Raises `Duffel.Error` if any page request fails.
  """
  @spec stream(t(), String.t(), keyword() | map()) :: Enumerable.t()
  def stream(%__MODULE__{} = client, path, params \\ []) do
    params = Map.new(params)

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
              {data, {:page, Map.put(params, :after, cursor)}}

            {:error, %Error{} = error} ->
              raise error

            {:error, exception} when is_exception(exception) ->
              raise exception
          end
      end,
      fn _ -> :ok end
    )
  end

  @doc false
  @spec request(t(), atom(), String.t(), keyword()) :: response()
  def request(%__MODULE__{} = client, method, path, opts \\ []) do
    {idempotency_key, opts} = Keyword.pop(opts, :idempotency_key)
    base_url = Keyword.get(opts, :base_url, client.base_url)

    headers =
      [{"duffel-version", client.api_version}, {"accept", "application/json"}] ++
        if idempotency_key, do: [{"idempotency-key", idempotency_key}], else: []

    req_options =
      [
        method: method,
        base_url: base_url,
        url: path,
        auth: {:bearer, client.access_token},
        headers: headers,
        compressed: true,
        retry: :transient
      ]
      |> Keyword.merge(Keyword.take(opts, [:params, :json]))
      |> Keyword.merge(client.req_options)

    metadata = %{method: method, path: path, base_url: base_url}

    :telemetry.span([:duffel, :request], metadata, fn ->
      response = Req.request(req_options)
      result = handle_response(response)

      stop_metadata =
        Map.merge(metadata, %{status: response_status(response), result: result_tag(result)})

      {result, stop_metadata}
    end)
  end

  defp response_status({:ok, %Req.Response{status: status}}), do: status
  defp response_status(_other), do: nil

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
    {:error, exception}
  end
end
