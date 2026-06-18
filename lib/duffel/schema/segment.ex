defmodule Duffel.Schema.Segment do
  @moduledoc """
  A single flight (one take-off and landing) within a slice.

  `origin`, `destination`, `marketing_carrier`, `operating_carrier` and
  `aircraft` are kept as raw maps. `stops` and `passengers` (per-segment fare
  detail, a different shape to `Duffel.Schema.Passenger`) are raw maps too.
  """

  defstruct [
    :id,
    :origin,
    :destination,
    :origin_terminal,
    :destination_terminal,
    :departing_at,
    :arriving_at,
    :duration,
    :distance,
    :marketing_carrier,
    :marketing_carrier_flight_number,
    :operating_carrier,
    :operating_carrier_flight_number,
    :aircraft,
    stops: [],
    passengers: []
  ]

  @type t :: %__MODULE__{
          id: String.t() | nil,
          origin: map() | nil,
          destination: map() | nil,
          origin_terminal: String.t() | nil,
          destination_terminal: String.t() | nil,
          departing_at: String.t() | nil,
          arriving_at: String.t() | nil,
          duration: String.t() | nil,
          distance: String.t() | nil,
          marketing_carrier: map() | nil,
          marketing_carrier_flight_number: String.t() | nil,
          operating_carrier: map() | nil,
          operating_carrier_flight_number: String.t() | nil,
          aircraft: map() | nil,
          stops: [map()],
          passengers: [map()]
        }

  @doc "Decodes a raw segment map into a `#{inspect(__MODULE__)}`."
  @spec from_map(map()) :: t()
  def from_map(map) when is_map(map) do
    %__MODULE__{
      id: map["id"],
      origin: map["origin"],
      destination: map["destination"],
      origin_terminal: map["origin_terminal"],
      destination_terminal: map["destination_terminal"],
      departing_at: map["departing_at"],
      arriving_at: map["arriving_at"],
      duration: map["duration"],
      distance: map["distance"],
      marketing_carrier: map["marketing_carrier"],
      marketing_carrier_flight_number: map["marketing_carrier_flight_number"],
      operating_carrier: map["operating_carrier"],
      operating_carrier_flight_number: map["operating_carrier_flight_number"],
      aircraft: map["aircraft"],
      stops: map["stops"] || [],
      passengers: map["passengers"] || []
    }
  end
end
