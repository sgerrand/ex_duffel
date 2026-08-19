defmodule Duffel.Schema.Cars.Search do
  @moduledoc """
  A cars search with the rates it returned.

  `rates` is a list of `Duffel.Schema.Cars.Rate` structs. `driver`,
  `pickup_location` and `dropoff_location` are kept as raw maps.
  """

  alias Duffel.Schema
  alias Duffel.Schema.Cars.Rate

  defstruct [
    :id,
    :live_mode,
    :created_at,
    :driver,
    :pickup_date,
    :pickup_time,
    :pickup_location,
    :dropoff_date,
    :dropoff_time,
    :dropoff_location,
    rates: []
  ]

  @type t :: %__MODULE__{
          id: String.t() | nil,
          live_mode: boolean() | nil,
          created_at: String.t() | nil,
          driver: map() | nil,
          pickup_date: String.t() | nil,
          pickup_time: String.t() | nil,
          pickup_location: map() | nil,
          dropoff_date: String.t() | nil,
          dropoff_time: String.t() | nil,
          dropoff_location: map() | nil,
          rates: [Rate.t()]
        }

  @doc "Decodes a raw cars search map into a `#{inspect(__MODULE__)}`."
  @spec from_map(map() | t()) :: t()
  def from_map(%__MODULE__{} = decoded), do: decoded

  def from_map(map) when is_map(map) do
    %__MODULE__{
      id: map["id"],
      live_mode: map["live_mode"],
      created_at: map["created_at"],
      driver: map["driver"],
      pickup_date: map["pickup_date"],
      pickup_time: map["pickup_time"],
      pickup_location: map["pickup_location"],
      dropoff_date: map["dropoff_date"],
      dropoff_time: map["dropoff_time"],
      dropoff_location: map["dropoff_location"],
      rates: Schema.cast_list(map["rates"], Rate)
    }
  end
end
