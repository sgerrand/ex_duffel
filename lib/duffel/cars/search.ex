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

  ## Examples

      Duffel.Cars.Search.create(client, %{
        pickup_datetime: "2026-07-01T10:00:00",
        dropoff_datetime: "2026-07-03T10:00:00",
        pickup_location: %{type: "airport", iata_code: "LHR"},
        driver_age: 30
      })

  """
  @spec create(Client.t(), map(), keyword()) :: {:ok, map()} | {:error, term()}
  def create(client, params, opts \\ []) do
    with {:ok, %{"data" => data}} <- Client.post(client, "/cars/search", params, opts) do
      {:ok, data}
    end
  end
end
