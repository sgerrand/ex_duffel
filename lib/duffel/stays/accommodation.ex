defmodule Duffel.Stays.Accommodation do
  @moduledoc """
  Look up accommodation, suggest accommodation by name or location, and
  read guest reviews.

  See the [Duffel documentation](https://duffel.com/docs/api/v2/stays-accommodation).
  """

  alias Duffel.{Client, Page}

  @path "/stays/accommodation"

  @doc """
  Lists one page of accommodation.

  ## Parameters

    * `:limit` / `:after` / `:before` - pagination (see `Duffel.Page`)

  """
  @spec list(Client.t(), keyword() | map()) :: {:ok, Page.t()} | {:error, term()}
  def list(client, params \\ []) do
    Client.list(client, @path, params)
  end

  @doc """
  Lazily streams all accommodation across pages.

  Raises `Duffel.Error` if a page request fails.
  """
  @spec stream(Client.t(), keyword() | map()) :: Enumerable.t()
  def stream(client, params \\ []) do
    Client.stream(client, @path, params)
  end

  @doc """
  Retrieves a single accommodation by ID.
  """
  @spec get(Client.t(), String.t()) :: {:ok, map()} | {:error, term()}
  def get(client, id) when is_binary(id) do
    with {:ok, %{"data" => data}} <- Client.get(client, "#{@path}/#{id}") do
      {:ok, data}
    end
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
  @spec suggestions(Client.t(), map()) :: {:ok, [map()]} | {:error, term()}
  def suggestions(client, params) do
    with {:ok, %{"data" => data}} <-
           Client.post(client, "#{@path}/suggestions", params) do
      {:ok, data}
    end
  end

  @doc """
  Lists guest reviews for an accommodation.

  Returns a map with a `"reviews"` list. Accepts `:limit`, `:after` and
  `:before` pagination parameters.
  """
  @spec reviews(Client.t(), String.t(), keyword() | map()) ::
          {:ok, map()} | {:error, term()}
  def reviews(client, id, params \\ []) when is_binary(id) do
    with {:ok, %{"data" => data}} <-
           Client.get(client, "#{@path}/#{id}/reviews", params: Map.new(params)) do
      {:ok, data}
    end
  end
end
