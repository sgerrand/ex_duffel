defmodule Duffel.Schema.Cars.Rate do
  @moduledoc """
  A bookable rate for a rental car.

  `car`, `supplier`, `mileage`, `charges` and `conditions` are kept as raw
  maps.
  """

  defstruct [
    :id,
    :total_amount,
    :total_currency,
    :base_amount,
    :base_currency,
    :payment_type,
    :car,
    :supplier,
    :mileage,
    charges: [],
    conditions: []
  ]

  @type t :: %__MODULE__{
          id: String.t() | nil,
          total_amount: String.t() | nil,
          total_currency: String.t() | nil,
          base_amount: String.t() | nil,
          base_currency: String.t() | nil,
          payment_type: String.t() | nil,
          car: map() | nil,
          supplier: map() | nil,
          mileage: map() | nil,
          charges: [map()],
          conditions: [map()]
        }

  @doc "Decodes a raw cars rate map into a `#{inspect(__MODULE__)}`."
  @spec from_map(map()) :: t()
  def from_map(map) when is_map(map) do
    %__MODULE__{
      id: map["id"],
      total_amount: map["total_amount"],
      total_currency: map["total_currency"],
      base_amount: map["base_amount"],
      base_currency: map["base_currency"],
      payment_type: map["payment_type"],
      car: map["car"],
      supplier: map["supplier"],
      mileage: map["mileage"],
      charges: map["charges"] || [],
      conditions: map["conditions"] || []
    }
  end
end
