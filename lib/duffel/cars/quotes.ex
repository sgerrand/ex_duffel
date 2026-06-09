defmodule Duffel.Cars.Quotes do
  @moduledoc """
  Confirm availability and the final price for a selected car rate.

  A quote is required before creating a booking.

  See the [Duffel documentation](https://duffel.com/docs/api/v2/cars-quotes).
  """

  alias Duffel.Client

  @doc """
  Creates a quote for a rate.

  ## Examples

      Duffel.Cars.Quotes.create(client, %{rate_id: "rat_123"})

  """
  @spec create(Client.t(), map(), keyword()) :: {:ok, map()} | {:error, term()}
  def create(client, params, opts \\ []) do
    with {:ok, %{"data" => data}} <- Client.post(client, "/cars/quotes", params, opts) do
      {:ok, data}
    end
  end
end
