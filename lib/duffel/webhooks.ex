defmodule Duffel.Webhooks do
  @moduledoc """
  Manage webhook subscriptions and verify incoming webhook signatures.

  ## Receiving webhooks

  Duffel signs every webhook delivery with the `X-Duffel-Signature`
  header. Verify it against the raw (unparsed) request body before
  trusting the payload:

      case Duffel.Webhooks.verify_signature(signature_header, raw_body, secret) do
        :ok -> handle_event(Jason.decode!(raw_body))
        {:error, reason} -> reject(reason)
      end

  See the [Duffel documentation](https://duffel.com/docs/api/v2/webhooks)
  and the [receiving webhooks guide](https://duffel.com/docs/guides/receiving-webhooks).
  """

  import Bitwise

  alias Duffel.{Client, Page}

  @path "/air/webhooks"

  @default_tolerance 300

  @doc """
  Creates a webhook subscription.

  The response includes the shared `secret` used to sign deliveries —
  it is only returned on creation, so store it.

  ## Examples

      Duffel.Webhooks.create(client, %{
        url: "https://example.com/webhooks/duffel",
        events: ["order.created", "order.airline_initiated_change_detected"]
      })

  """
  @spec create(Client.t(), map(), keyword()) :: {:ok, map()} | {:error, term()}
  def create(client, params, opts \\ []) do
    with {:ok, %{"data" => data}} <- Client.post(client, @path, params, opts) do
      {:ok, data}
    end
  end

  @doc """
  Lists one page of webhooks.

  ## Parameters

    * `:limit` / `:after` / `:before` - pagination (see `Duffel.Page`)

  """
  @spec list(Client.t(), keyword() | map()) :: {:ok, Page.t()} | {:error, term()}
  def list(client, params \\ []) do
    Client.list(client, @path, params)
  end

  @doc """
  Lazily streams all webhooks across pages.

  Raises `Duffel.Error` if a page request fails.
  """
  @spec stream(Client.t(), keyword() | map()) :: Enumerable.t()
  def stream(client, params \\ []) do
    Client.stream(client, @path, params)
  end

  @doc """
  Updates a webhook's URL, subscribed events or active status.

  ## Examples

      Duffel.Webhooks.update(client, "sev_123", %{active: false})

  """
  @spec update(Client.t(), String.t(), map()) :: {:ok, map()} | {:error, term()}
  def update(client, id, params) when is_binary(id) do
    with {:ok, %{"data" => data}} <- Client.patch(client, "#{@path}/#{id}", params) do
      {:ok, data}
    end
  end

  @doc """
  Deletes a webhook subscription.
  """
  @spec delete(Client.t(), String.t()) :: :ok | {:error, term()}
  def delete(client, id) when is_binary(id) do
    with {:ok, _body} <- Client.delete(client, "#{@path}/#{id}") do
      :ok
    end
  end

  @doc """
  Sends a test (ping) event to the webhook's URL.
  """
  @spec ping(Client.t(), String.t()) :: :ok | {:error, term()}
  def ping(client, id) when is_binary(id) do
    with {:ok, _body} <- Client.post(client, "#{@path}/#{id}/actions/ping", %{}) do
      :ok
    end
  end

  @doc """
  Verifies the `X-Duffel-Signature` header of a webhook delivery.

  The header has the form `t=<unix timestamp>,v1=<signature>`, where the
  signature is the lowercase hex HMAC-SHA256 of `"<timestamp>.<raw body>"`
  keyed with the webhook's shared secret. `raw_body` must be the exact
  bytes received — verify before any JSON parsing or re-encoding.

  Comparison is constant-time. Deliveries older than `:tolerance`
  seconds (default #{@default_tolerance}) are rejected to limit replay
  attacks; pass `tolerance: :infinity` to disable the timestamp check.

  ## Options

    * `:tolerance` - max allowed age in seconds, or `:infinity`
      (default `#{@default_tolerance}`)
    * `:now` - current unix time in seconds, for testing
      (default `System.system_time(:second)`)

  ## Return values

    * `:ok` - signature is valid
    * `{:error, :invalid_format}` - header missing or malformed
    * `{:error, :invalid_signature}` - signature does not match
    * `{:error, :timestamp_out_of_tolerance}` - delivery too old

  """
  @spec verify_signature(String.t() | nil, binary(), String.t(), keyword()) ::
          :ok | {:error, :invalid_format | :invalid_signature | :timestamp_out_of_tolerance}
  def verify_signature(signature_header, raw_body, secret, opts \\ [])

  def verify_signature(signature_header, raw_body, secret, opts)
      when is_binary(signature_header) and is_binary(raw_body) and is_binary(secret) do
    tolerance = Keyword.get(opts, :tolerance, @default_tolerance)
    now = Keyword.get_lazy(opts, :now, fn -> System.system_time(:second) end)

    with {:ok, timestamp, signatures} <- parse_header(signature_header),
         :ok <- check_tolerance(timestamp, now, tolerance) do
      expected =
        :hmac
        |> :crypto.mac(:sha256, secret, "#{timestamp}.#{raw_body}")
        |> Base.encode16(case: :lower)

      if Enum.any?(signatures, &secure_compare(&1, expected)) do
        :ok
      else
        {:error, :invalid_signature}
      end
    end
  end

  def verify_signature(_signature_header, _raw_body, _secret, _opts) do
    {:error, :invalid_format}
  end

  defp parse_header(header) do
    parts =
      header
      |> String.split(",")
      |> Enum.flat_map(fn pair ->
        case String.split(pair, "=", parts: 2) do
          [key, value] -> [{String.trim(key), value}]
          _other -> []
        end
      end)

    timestamp = :proplists.get_value("t", parts, nil)
    signatures = for {"v1", signature} <- parts, do: String.downcase(signature)

    with true <- is_binary(timestamp) and signatures != [],
         {parsed, ""} <- Integer.parse(timestamp) do
      {:ok, parsed, signatures}
    else
      _invalid -> {:error, :invalid_format}
    end
  end

  defp check_tolerance(_timestamp, _now, :infinity), do: :ok

  defp check_tolerance(timestamp, now, tolerance)
       when is_integer(tolerance) and now - timestamp <= tolerance do
    :ok
  end

  defp check_tolerance(_timestamp, _now, _tolerance) do
    {:error, :timestamp_out_of_tolerance}
  end

  # Constant-time comparison; does not depend on OTP 25+ :crypto.hash_equals
  # or a runtime plug dependency.
  defp secure_compare(left, right) when byte_size(left) == byte_size(right) do
    secure_compare(left, right, 0)
  end

  defp secure_compare(_left, _right), do: false

  defp secure_compare(<<l, left::binary>>, <<r, right::binary>>, acc) do
    secure_compare(left, right, acc ||| bxor(l, r))
  end

  defp secure_compare(<<>>, <<>>, acc), do: acc == 0
end
