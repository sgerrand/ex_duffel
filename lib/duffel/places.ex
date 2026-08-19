defmodule Duffel.Places do
  @moduledoc """
  Autocomplete airports and cities by name or location.

  See the [Duffel documentation](https://duffel.com/docs/api/v2/places).
  """

  alias Duffel.{Client, Error}

  @path "/places/suggestions"

  @doc """
  Suggests places matching a search string or location. Not paginated.

  ## Parameters

    * `:query` - search string, e.g. a partial city or airport name
    * `:lat` / `:lng` / `:rad` - latitude, longitude and radius in metres
      to search around

  ## Examples

      Duffel.Places.suggestions(client, query: "lond")

  """
  @spec suggestions(Client.t(), keyword() | map()) :: {:ok, [map()]} | {:error, Error.t()}
  def suggestions(client, params) do
    client |> Client.get(@path, params: Map.new(params)) |> Client.unwrap()
  end
end
