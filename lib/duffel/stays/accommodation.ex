defmodule Duffel.Stays.Accommodation do
  @moduledoc """
  Look up accommodation, suggest accommodation by name or location, and
  read guest reviews.

  See the [Duffel documentation](https://duffel.com/docs/api/v2/stays-accommodation).
  """

  alias Duffel.{Client, Error, Page}

  @path "/stays/accommodation"

  @doc """
  Lists one page of accommodation around a point.

  ## Parameters

    * `:latitude` - centre of the search, in decimal degrees (required)
    * `:longitude` - centre of the search, in decimal degrees (required)
    * `:radius` - how far to search, in kilometres, 1..100 (default 5)
    * `:limit` / `:after` / `:before` - pagination (see `Duffel.Page`)

  ## Examples

      Duffel.Stays.Accommodation.list(client, latitude: 51.5074, longitude: -0.1278)

  """
  @spec list(Client.t(), keyword() | map()) :: {:ok, Page.t()} | {:error, Error.t()}
  def list(client, params) do
    Client.list(client, @path, params)
  end

  @doc """
  Lazily streams all accommodation around a point, across pages.

  Takes the same parameters as `list/2`. Raises `Duffel.Error` if a page
  request fails.
  """
  @spec stream(Client.t(), keyword() | map()) :: Enumerable.t()
  def stream(client, params) do
    Client.stream(client, @path, params)
  end

  @doc """
  Retrieves a single accommodation by ID.
  """
  @spec get(Client.t(), String.t()) :: {:ok, map()} | {:error, Error.t()}
  def get(client, id) when is_binary(id) do
    Client.get_data(client, "#{@path}/#{id}")
  end

  @doc """
  Suggests accommodation matching a search string or location. Not
  paginated.

  ## Examples

      Duffel.Stays.Accommodation.suggestions(client, %{
        query: "the savoy",
        location: %{
          radius: 5,
          geographic_coordinates: %{latitude: 51.5074, longitude: -0.1278}
        }
      })

  """
  @spec suggestions(Client.t(), map()) :: {:ok, [map()]} | {:error, Error.t()}
  def suggestions(client, params) do
    Client.post_data(client, "#{@path}/suggestions", params)
  end

  @doc """
  Lists guest reviews for an accommodation.

  Returns a map with a `"reviews"` list. Accepts `:limit`, `:after` and
  `:before` pagination parameters.
  """
  @spec reviews(Client.t(), String.t(), keyword() | map()) ::
          {:ok, map()} | {:error, Error.t()}
  def reviews(client, id, params \\ []) when is_binary(id) do
    Client.get_data(client, "#{@path}/#{id}/reviews", params: Map.new(params))
  end
end
