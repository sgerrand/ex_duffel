defmodule Duffel.Cars.Bookings do
  @moduledoc """
  Book a rental car from a quote, then retrieve or cancel the booking.

  See the [Duffel documentation](https://duffel.com/docs/api/v2/cars-bookings).
  """

  alias Duffel.Client

  @path "/cars/bookings"

  @doc """
  Creates a booking from a quote.

  ## Options

    * `:idempotency_key` - sets the `Idempotency-Key` header

  ## Examples

      Duffel.Cars.Bookings.create(
        client,
        %{
          quote_id: "quo_123",
          driver: %{given_name: "Amelia", family_name: "Earhart"},
          email: "amelia@duffel.com",
          phone_number: "+442080160508"
        },
        idempotency_key: "car-booking-1"
      )

  """
  @spec create(Client.t(), map(), keyword()) :: {:ok, map()} | {:error, term()}
  def create(client, params, opts \\ []) do
    with {:ok, %{"data" => data}} <- Client.post(client, @path, params, opts) do
      {:ok, data}
    end
  end

  @doc """
  Retrieves a single booking by ID.
  """
  @spec get(Client.t(), String.t()) :: {:ok, map()} | {:error, term()}
  def get(client, id) when is_binary(id) do
    with {:ok, %{"data" => data}} <- Client.get(client, "#{@path}/#{id}") do
      {:ok, data}
    end
  end

  @doc """
  Cancels a booking.
  """
  @spec cancel(Client.t(), String.t()) :: {:ok, map()} | {:error, term()}
  def cancel(client, id) when is_binary(id) do
    with {:ok, %{"data" => data}} <-
           Client.post(client, "#{@path}/#{id}/actions/cancel", %{}) do
      {:ok, data}
    end
  end
end
