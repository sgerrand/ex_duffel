defmodule Duffel.Cars.Bookings do
  @moduledoc """
  Book a rental car from a quote, then retrieve or cancel the booking.

  See the [Duffel documentation](https://duffel.com/docs/api/v2/cars-bookings).
  """

  alias Duffel.{Client, Error}

  @path "/cars/bookings"

  @doc """
  Creates a booking from a quote.

  ## Options

    * `:idempotency_key` - value for the `Idempotency-Key` header. A key is
      generated when you do not pass one (see `Duffel.Client.post/4`).

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
  @spec create(Client.t(), map(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def create(client, params, opts \\ []) do
    client |> Client.post(@path, params, opts) |> Client.unwrap()
  end

  @doc """
  Retrieves a single booking by ID.
  """
  @spec get(Client.t(), String.t()) :: {:ok, map()} | {:error, Error.t()}
  def get(client, id) when is_binary(id) do
    client |> Client.get("#{@path}/#{id}") |> Client.unwrap()
  end

  @doc """
  Cancels a booking.
  """
  @spec cancel(Client.t(), String.t()) :: {:ok, map()} | {:error, Error.t()}
  def cancel(client, id) when is_binary(id) do
    client |> Client.post("#{@path}/#{id}/actions/cancel", %{}) |> Client.unwrap()
  end
end
