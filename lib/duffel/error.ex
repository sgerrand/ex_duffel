defmodule Duffel.Error do
  @moduledoc """
  The error every Duffel function returns when something goes wrong.

  A failed call always gives you `{:error, %Duffel.Error{}}`, whether the
  API rejected the request or the request never reached it, so one clause
  covers both:

      case Duffel.Orders.create(client, params) do
        {:ok, order} -> ...
        {:error, %Duffel.Error{type: :rate_limit_error}} -> retry_later()
        {:error, %Duffel.Error{type: :validation_error, source: source}} -> ...
        {:error, %Duffel.Error{type: :transport_error}} -> retry_later()
      end

  ## API errors

  These mirror the [Duffel error schema](https://duffel.com/docs/api/overview/errors).
  The struct fields come from the first error in the response; the full
  list is under `:errors`, and `:status` holds the HTTP status. `:type` is
  one of `:airline_error`, `:api_error`, `:authentication_error`,
  `:invalid_request_error`, `:invalid_state_error`, `:rate_limit_error` or
  `:validation_error`. A type Duffel adds later reads as `:unknown_error`.

  ## Transport errors

  When the request could not be completed at all — connection refused, DNS
  failure, timeout — `:type` is `:transport_error` and `:status` is `nil`.
  The underlying exception, usually a `Req.TransportError`, is kept under
  `:reason` for when you need to tell those cases apart.

  ## Rate limits

  `:rate_limit` holds a `Duffel.RateLimit` whenever the response reported
  your remaining allowance, which is most useful on a
  `:rate_limit_error`:

      {:error, %Duffel.Error{type: :rate_limit_error, rate_limit: rate_limit}} ->
        retry_in(rate_limit.retry_after_ms)

  ## Unexpected responses

  Duffel wraps every resource in a `data` envelope. A success response
  without one means the endpoint returned something this library does not
  know how to read, so `:type` is `:unexpected_response` and the body is
  kept under `:reason`.
  """

  @known_types ~w(
    airline_error
    api_error
    authentication_error
    invalid_request_error
    invalid_state_error
    rate_limit_error
    validation_error
  )a

  defexception [
    :type,
    :code,
    :title,
    :message,
    :documentation_url,
    :source,
    :request_id,
    :status,
    :reason,
    :rate_limit,
    errors: []
  ]

  @type t :: %__MODULE__{
          type: atom() | nil,
          code: String.t() | nil,
          title: String.t() | nil,
          message: String.t() | nil,
          documentation_url: String.t() | nil,
          source: map() | nil,
          request_id: String.t() | nil,
          status: pos_integer() | nil,
          reason: term(),
          rate_limit: Duffel.RateLimit.t() | nil,
          errors: [map()]
        }

  @impl true
  def message(%__MODULE__{status: nil} = error) do
    "Duffel request failed: #{error.message || error.title || "unknown error"}"
  end

  def message(%__MODULE__{} = error) do
    detail = error.message || error.title || "unknown error"
    "Duffel API error (HTTP #{error.status}): #{detail}"
  end

  @doc false
  @spec from_response(Req.Response.t()) :: t()
  def from_response(%Req.Response{status: status, body: body} = response) do
    {errors, request_id} =
      case body do
        %{"errors" => errors} = body when is_list(errors) ->
          {errors, get_in(body, ["meta", "request_id"])}

        _other ->
          {[], nil}
      end

    first = List.first(errors) || %{}

    %__MODULE__{
      type: parse_type(first["type"]),
      code: first["code"],
      title: first["title"],
      message: first["message"],
      documentation_url: first["documentation_url"],
      source: first["source"],
      request_id: request_id,
      status: status,
      rate_limit: Duffel.RateLimit.from_response(response),
      errors: errors
    }
  end

  @doc false
  @spec unexpected_response(term()) :: t()
  def unexpected_response(body) do
    %__MODULE__{
      type: :unexpected_response,
      title: "Unexpected response",
      message: ~s(the response body has no "data" key),
      reason: body
    }
  end

  @doc false
  @spec from_exception(Exception.t()) :: t()
  def from_exception(exception) do
    %__MODULE__{
      type: :transport_error,
      title: "Transport error",
      message: Exception.message(exception),
      reason: exception
    }
  end

  for type <- @known_types do
    defp parse_type(unquote(Atom.to_string(type))), do: unquote(type)
  end

  defp parse_type(_other), do: :unknown_error
end
