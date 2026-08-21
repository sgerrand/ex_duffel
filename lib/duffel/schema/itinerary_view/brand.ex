defmodule Duffel.Schema.ItineraryView.Brand do
  @moduledoc """
  A fare brand available on an itinerary, and the offers priced under it.

  Offers stay raw maps: Duffel's guide shows only some of their fields for
  this shape, so a struct would drop the rest. Each one carries a `"type"`
  of `"single_ticket"` or `"split_ticket"`, and names its airline under
  `"owner"` as an ID for `Duffel.Schema.ItineraryView.airline/2`.
  """

  defstruct [:fare_brand_name, offers: []]

  @type t :: %__MODULE__{
          fare_brand_name: String.t() | nil,
          offers: [map()]
        }

  @doc "Decodes a raw fare brand into a `#{inspect(__MODULE__)}`."
  @spec from_map(map() | t()) :: t()
  def from_map(%__MODULE__{} = decoded), do: decoded

  def from_map(map) when is_map(map) do
    %__MODULE__{
      fare_brand_name: map["fare_brand_name"],
      offers: map["offers"] || []
    }
  end
end
