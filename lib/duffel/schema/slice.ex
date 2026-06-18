defmodule Duffel.Schema.Slice do
  @moduledoc """
  One leg of a journey on an offer or order.

  `segments` is a list of `Duffel.Schema.Segment` structs. `origin`,
  `destination` and `conditions` are kept as raw maps.
  """

  alias Duffel.Schema
  alias Duffel.Schema.Segment

  defstruct [
    :id,
    :origin,
    :destination,
    :origin_type,
    :destination_type,
    :duration,
    :fare_brand_name,
    :conditions,
    segments: []
  ]

  @type t :: %__MODULE__{
          id: String.t() | nil,
          origin: map() | nil,
          destination: map() | nil,
          origin_type: String.t() | nil,
          destination_type: String.t() | nil,
          duration: String.t() | nil,
          fare_brand_name: String.t() | nil,
          conditions: map() | nil,
          segments: [Segment.t()]
        }

  @doc "Decodes a raw slice map into a `#{inspect(__MODULE__)}`."
  @spec from_map(map()) :: t()
  def from_map(map) when is_map(map) do
    %__MODULE__{
      id: map["id"],
      origin: map["origin"],
      destination: map["destination"],
      origin_type: map["origin_type"],
      destination_type: map["destination_type"],
      duration: map["duration"],
      fare_brand_name: map["fare_brand_name"],
      conditions: map["conditions"],
      segments: Schema.cast_list(map["segments"], Segment)
    }
  end
end
