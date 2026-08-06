defmodule Duffel.Schema.Cars.Quote do
  @moduledoc """
  A confirmed price for a rate, ready to book.

  `car`, `supplier`, `mileage`, `pickup_location`, `dropoff_location`,
  `charges`, `conditions` and `privacy_policies` are kept as raw maps.
  """

  defstruct [
    :id,
    :live_mode,
    :rate_id,
    :search_id,
    :total_amount,
    :total_currency,
    :base_amount,
    :base_currency,
    :payment_type,
    :pickup_date,
    :pickup_time,
    :pickup_location,
    :dropoff_date,
    :dropoff_time,
    :dropoff_location,
    :car,
    :supplier,
    :mileage,
    charges: [],
    conditions: [],
    privacy_policies: []
  ]

  @type t :: %__MODULE__{
          id: String.t() | nil,
          live_mode: boolean() | nil,
          rate_id: String.t() | nil,
          search_id: String.t() | nil,
          total_amount: String.t() | nil,
          total_currency: String.t() | nil,
          base_amount: String.t() | nil,
          base_currency: String.t() | nil,
          payment_type: String.t() | nil,
          pickup_date: String.t() | nil,
          pickup_time: String.t() | nil,
          pickup_location: map() | nil,
          dropoff_date: String.t() | nil,
          dropoff_time: String.t() | nil,
          dropoff_location: map() | nil,
          car: map() | nil,
          supplier: map() | nil,
          mileage: map() | nil,
          charges: [map()],
          conditions: [map()],
          privacy_policies: [map()]
        }

  @doc "Decodes a raw cars quote map into a `#{inspect(__MODULE__)}`."
  @spec from_map(map()) :: t()
  def from_map(map) when is_map(map) do
    %__MODULE__{
      id: map["id"],
      live_mode: map["live_mode"],
      rate_id: map["rate_id"],
      search_id: map["search_id"],
      total_amount: map["total_amount"],
      total_currency: map["total_currency"],
      base_amount: map["base_amount"],
      base_currency: map["base_currency"],
      payment_type: map["payment_type"],
      pickup_date: map["pickup_date"],
      pickup_time: map["pickup_time"],
      pickup_location: map["pickup_location"],
      dropoff_date: map["dropoff_date"],
      dropoff_time: map["dropoff_time"],
      dropoff_location: map["dropoff_location"],
      car: map["car"],
      supplier: map["supplier"],
      mileage: map["mileage"],
      charges: map["charges"] || [],
      conditions: map["conditions"] || [],
      privacy_policies: map["privacy_policies"] || []
    }
  end
end
