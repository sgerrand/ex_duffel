defmodule Duffel.Schema.Cars.Booking do
  @moduledoc """
  A booked rental car.

  `driver`, `car`, `supplier`, `mileage`, `pickup_location`,
  `dropoff_location`, `charges`, `conditions`, `privacy_policies` and
  `metadata` are kept as raw maps.
  """

  defstruct [
    :id,
    :live_mode,
    :reference,
    :status,
    :quote_id,
    :driver,
    :car,
    :supplier,
    :pickup_date,
    :pickup_time,
    :pickup_location,
    :dropoff_date,
    :dropoff_time,
    :dropoff_location,
    :total_amount,
    :total_currency,
    :base_amount,
    :base_currency,
    :payment_type,
    :mileage,
    :confirmed_at,
    :cancelled_at,
    :metadata,
    charges: [],
    conditions: [],
    privacy_policies: [],
    users: []
  ]

  @type t :: %__MODULE__{
          id: String.t() | nil,
          live_mode: boolean() | nil,
          reference: String.t() | nil,
          status: String.t() | nil,
          quote_id: String.t() | nil,
          driver: map() | nil,
          car: map() | nil,
          supplier: map() | nil,
          pickup_date: String.t() | nil,
          pickup_time: String.t() | nil,
          pickup_location: map() | nil,
          dropoff_date: String.t() | nil,
          dropoff_time: String.t() | nil,
          dropoff_location: map() | nil,
          total_amount: String.t() | nil,
          total_currency: String.t() | nil,
          base_amount: String.t() | nil,
          base_currency: String.t() | nil,
          payment_type: String.t() | nil,
          mileage: map() | nil,
          confirmed_at: String.t() | nil,
          cancelled_at: String.t() | nil,
          metadata: map() | nil,
          charges: [map()],
          conditions: [map()],
          privacy_policies: [map()],
          users: [String.t()]
        }

  @doc "Decodes a raw cars booking map into a `#{inspect(__MODULE__)}`."
  @spec from_map(map() | t()) :: t()
  def from_map(%__MODULE__{} = decoded), do: decoded

  def from_map(map) when is_map(map) do
    %__MODULE__{
      id: map["id"],
      live_mode: map["live_mode"],
      reference: map["reference"],
      status: map["status"],
      quote_id: map["quote_id"],
      driver: map["driver"],
      car: map["car"],
      supplier: map["supplier"],
      pickup_date: map["pickup_date"],
      pickup_time: map["pickup_time"],
      pickup_location: map["pickup_location"],
      dropoff_date: map["dropoff_date"],
      dropoff_time: map["dropoff_time"],
      dropoff_location: map["dropoff_location"],
      total_amount: map["total_amount"],
      total_currency: map["total_currency"],
      base_amount: map["base_amount"],
      base_currency: map["base_currency"],
      payment_type: map["payment_type"],
      mileage: map["mileage"],
      confirmed_at: map["confirmed_at"],
      cancelled_at: map["cancelled_at"],
      metadata: map["metadata"],
      charges: map["charges"] || [],
      conditions: map["conditions"] || [],
      privacy_policies: map["privacy_policies"] || [],
      users: map["users"] || []
    }
  end
end
