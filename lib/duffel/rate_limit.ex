defmodule Duffel.RateLimit do
  @moduledoc """
  What a response said about your remaining request allowance.

  Duffel reports the allowance in response headers. This struct holds
  whichever of them arrived; a field is `nil` when its header was absent
  or unreadable, and the whole struct is `nil` when none of them were
  sent.

  You get one on a `Duffel.Error` and on every `[:duffel, :request, :stop]`
  telemetry event, so you can slow down before Duffel starts refusing
  requests rather than after:

      :telemetry.attach(
        "duffel-rate-limit",
        [:duffel, :request, :stop],
        fn _event, _measurements, %{rate_limit: rate_limit}, _config ->
          if rate_limit && rate_limit.remaining && rate_limit.remaining < 10 do
            Logger.warning("duffel allowance nearly spent: \#{rate_limit.remaining}")
          end
        end,
        nil
      )

  Requests that hit the limit are retried automatically, honouring
  `retry-after`, so reach for this when you want to shape your own traffic
  or to decide what to do once the retries are spent.
  """

  defstruct [:limit, :remaining, :reset, :retry_after_ms]

  @type t :: %__MODULE__{
          limit: non_neg_integer() | nil,
          remaining: non_neg_integer() | nil,
          reset: String.t() | nil,
          retry_after_ms: non_neg_integer() | nil
        }

  @doc false
  @spec from_response(Req.Response.t()) :: t() | nil
  def from_response(%Req.Response{} = response) do
    rate_limit = %__MODULE__{
      limit: integer_header(response, "ratelimit-limit"),
      remaining: integer_header(response, "ratelimit-remaining"),
      # Kept as sent: Duffel documents no format for this one.
      reset: header(response, "ratelimit-reset"),
      retry_after_ms: Req.Response.get_retry_after(response)
    }

    if rate_limit == %__MODULE__{}, do: nil, else: rate_limit
  end

  defp header(response, name) do
    case Req.Response.get_header(response, name) do
      [value | _rest] -> value
      [] -> nil
    end
  end

  defp integer_header(response, name) do
    with value when is_binary(value) <- header(response, name),
         {integer, ""} <- Integer.parse(value) do
      integer
    else
      _unreadable -> nil
    end
  end
end
