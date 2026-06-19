defmodule Duffel.Cars.Search do
  @moduledoc """
  Search for rental cars.

  A search returns the available rates; create a quote for a chosen rate
  before booking.

  See the [Duffel documentation](https://duffel.com/docs/api/v2/cars-search).
  """

  alias Duffel.Client

  @doc """
  Searches for rental cars.

  Build the params by hand or with `Duffel.Cars.SearchParams`.

  ## Examples

      params =
        Duffel.Cars.SearchParams.new(
          driver: Duffel.Cars.SearchParams.driver(age: 30),
          pickup_date: "2026-07-01",
          pickup_time: "10:00",
          pickup_location: Duffel.Cars.SearchParams.at_airport("LHR"),
          dropoff_date: "2026-07-03",
          dropoff_time: "10:00",
          dropoff_location: Duffel.Cars.SearchParams.at_airport("LHR")
        )

      Duffel.Cars.Search.create(client, params)

  """
  @spec create(Client.t(), map(), keyword()) :: {:ok, map()} | {:error, term()}
  def create(client, params, opts \\ []) do
    with {:ok, %{"data" => data}} <- Client.post(client, "/cars/search", params, opts) do
      {:ok, data}
    end
  end
end
