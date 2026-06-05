defmodule Duffel.Places do
  @moduledoc """
  Autocomplete airports and cities by name or location.

  See the [Duffel documentation](https://duffel.com/docs/api/v2/places).
  """

  alias Duffel.Client

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
  @spec suggestions(Client.t(), keyword() | map()) :: {:ok, [map()]} | {:error, term()}
  def suggestions(client, params) do
    with {:ok, %{"data" => data}} <- Client.get(client, @path, params: Map.new(params)) do
      {:ok, data}
    end
  end
end
