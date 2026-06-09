defmodule Duffel.Stays.Search do
  @moduledoc """
  Search for accommodation and fetch the rates for a result.

  A search returns the cheapest rate per accommodation. To see every
  room and rate for one result, call `fetch_all_rates/2`.

  See the [Duffel documentation](https://duffel.com/docs/api/v2/stays-search).
  """

  alias Duffel.Client

  @doc """
  Searches for accommodation.

  Returns a map with `"results"` (the matching accommodation) and
  `"created_at"`.

  ## Examples

      Duffel.Stays.Search.create(client, %{
        check_in_date: "2026-07-01",
        check_out_date: "2026-07-03",
        rooms: 1,
        guests: [%{type: "adult"}],
        location: %{
          radius: 5,
          geographic_coordinates: %{latitude: 51.5074, longitude: -0.1278}
        }
      })

  """
  @spec create(Client.t(), map(), keyword()) :: {:ok, map()} | {:error, term()}
  def create(client, params, opts \\ []) do
    with {:ok, %{"data" => data}} <- Client.post(client, "/stays/search", params, opts) do
      {:ok, data}
    end
  end

  @doc """
  Fetches every room and rate for a search result.
  """
  @spec fetch_all_rates(Client.t(), String.t()) :: {:ok, map()} | {:error, term()}
  def fetch_all_rates(client, search_result_id) when is_binary(search_result_id) do
    path = "/stays/search_results/#{search_result_id}/actions/fetch_all_rates"

    with {:ok, %{"data" => data}} <- Client.post(client, path, %{}) do
      {:ok, data}
    end
  end
end
