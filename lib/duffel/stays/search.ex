defmodule Duffel.Stays.Search do
  @moduledoc """
  Search for accommodation and fetch the rates for a result.

  A search returns the cheapest rate per accommodation. To see every
  room and rate for one result, call `fetch_all_rates/2`.

  See the [Duffel documentation](https://duffel.com/docs/api/v2/stays-search).
  """

  alias Duffel.{Client, Error}

  @doc """
  Searches for accommodation.

  Returns a map with `"results"` (the matching accommodation) and
  `"created_at"`. Build the params by hand or with
  `Duffel.Stays.SearchParams`.

  ## Examples

      params =
        Duffel.Stays.SearchParams.new(
          check_in_date: "2026-07-01",
          check_out_date: "2026-07-03",
          guests: [%{type: "adult"}],
          location: Duffel.Stays.SearchParams.around(51.5074, -0.1278)
        )

      Duffel.Stays.Search.create(client, params)

  """
  @spec create(Client.t(), map(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def create(client, params, opts \\ []) do
    Client.post_data(client, "/stays/search", params, opts)
  end

  @doc """
  Fetches every room and rate for a search result.
  """
  @spec fetch_all_rates(Client.t(), String.t()) :: {:ok, map()} | {:error, Error.t()}
  def fetch_all_rates(client, search_result_id) when is_binary(search_result_id) do
    path = "/stays/search_results/#{search_result_id}/actions/fetch_all_rates"

    Client.post_data(client, path, %{})
  end
end
