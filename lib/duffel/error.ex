defmodule Duffel.Error do
  @moduledoc """
  Represents an error response from the Duffel API.

  Mirrors the [Duffel error schema](https://duffel.com/docs/api/overview/errors).
  The struct fields are populated from the first error in the response;
  the full list is available under `:errors`.

  `:type` is converted to an atom for pattern matching, e.g.:

      case Duffel.Orders.create(client, params) do
        {:ok, order} -> ...
        {:error, %Duffel.Error{type: :rate_limit_error}} -> retry_later()
        {:error, %Duffel.Error{type: :validation_error, source: source}} -> ...
      end

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
          errors: [map()]
        }

  @impl true
  def message(%__MODULE__{} = error) do
    detail = error.message || error.title || "unknown error"
    "Duffel API error (HTTP #{error.status || "?"}): #{detail}"
  end

  @doc false
  @spec from_response(Req.Response.t()) :: t()
  def from_response(%Req.Response{status: status, body: body}) do
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
      errors: errors
    }
  end

  for type <- @known_types do
    defp parse_type(unquote(Atom.to_string(type))), do: unquote(type)
  end

  defp parse_type(_other), do: :unknown_error
end
