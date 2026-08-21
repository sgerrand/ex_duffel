defmodule Duffel.Schema.ItineraryView.Slice do
  @moduledoc """
  One slice of an offer request in the `itineraries` shape.

  `origin` and `destination` are place IDs — resolve them with
  `Duffel.Schema.ItineraryView.place/2`.
  """

  alias Duffel.Schema
  alias Duffel.Schema.ItineraryView.Itinerary

  defstruct [
    :origin,
    :destination,
    itineraries: []
  ]

  @type t :: %__MODULE__{
          origin: String.t() | nil,
          destination: String.t() | nil,
          itineraries: [Itinerary.t()]
        }

  @doc "Decodes a raw slice into a `#{inspect(__MODULE__)}`."
  @spec from_map(map() | t()) :: t()
  def from_map(%__MODULE__{} = decoded), do: decoded

  def from_map(map) when is_map(map) do
    %__MODULE__{
      origin: map["origin"],
      destination: map["destination"],
      itineraries: Schema.cast_list(map["itineraries"], Itinerary)
    }
  end
end
