defmodule Duffel.Schema.ItineraryView.Itinerary do
  @moduledoc """
  A set of flights shared by every offer beneath it: the same segments, in
  the same order, in the same cabins. The fares that can be bought on
  those flights are the `brands`.

  `segments` stay raw maps. They name their carriers and places by ID
  rather than inline, and Duffel does not document their fields for this
  shape, so decoding them into `Duffel.Schema.Segment` would be wrong.
  """

  alias Duffel.Schema
  alias Duffel.Schema.ItineraryView.Brand

  defstruct segments: [], brands: []

  @type t :: %__MODULE__{
          segments: [map()],
          brands: [Brand.t()]
        }

  @doc "Decodes a raw itinerary into a `#{inspect(__MODULE__)}`."
  @spec from_map(map() | t()) :: t()
  def from_map(%__MODULE__{} = decoded), do: decoded

  def from_map(map) when is_map(map) do
    %__MODULE__{
      segments: map["segments"] || [],
      brands: Schema.cast_list(map["brands"], Brand)
    }
  end
end
