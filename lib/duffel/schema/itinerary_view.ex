defmodule Duffel.Schema.ItineraryView do
  @moduledoc """
  An offer request returned in the `itineraries` shape.

  Ask for this shape with `view: "itineraries"`, then decode the response:

      {:ok, raw} = Duffel.OfferRequests.get(client, "orq_123", params: [view: "itineraries"])
      view = Duffel.Schema.ItineraryView.from_map(raw)

  Instead of a flat list of offers, the offers are grouped: a slice per
  slice you searched for, an itinerary per set of identical flights, a
  brand per fare on those flights, and the priced offers inside each
  brand. It is also the only shape that carries split-ticket itineraries.

  Airlines, places and aircraft appear once under `references` and are
  named by ID everywhere else, which is what makes this shape smaller over
  the wire. Use `airline/2`, `place/2` and `aircraft/2` to look them up:

      slice = hd(view.slices)
      Duffel.Schema.ItineraryView.place(view, slice.origin)
      #=> %{"iata_code" => "JFK", "type" => "airport"}

  Segments and the offers inside a brand stay raw maps. Duffel documents
  the tree but not the fields at those two levels, and a struct would drop
  what it does not know about.

  See [Choosing your search response
  format](https://duffel.com/docs/guides/choosing-your-search-response-format).
  """

  alias Duffel.Schema
  alias Duffel.Schema.ItineraryView.Slice

  defstruct [
    :id,
    references: %{},
    slices: []
  ]

  @type t :: %__MODULE__{
          id: String.t() | nil,
          references: map(),
          slices: [Slice.t()]
        }

  @doc "Decodes a raw itineraries-shaped offer request into a `#{inspect(__MODULE__)}`."
  @spec from_map(map() | t()) :: t()
  def from_map(%__MODULE__{} = decoded), do: decoded

  def from_map(map) when is_map(map) do
    %__MODULE__{
      id: map["id"],
      references: map["references"] || %{},
      slices: Schema.cast_list(map["slices"], Slice)
    }
  end

  @doc """
  Looks up an airline by the ID used elsewhere in the tree, such as an
  offer's `"owner"`. Returns `nil` when the response does not name it.
  """
  @spec airline(t(), String.t() | nil) :: map() | nil
  def airline(%__MODULE__{} = view, id), do: reference(view, "airlines", id)

  @doc """
  Looks up a place — an airport or a city — by ID, such as a slice's
  `origin`. Returns `nil` when the response does not name it.
  """
  @spec place(t(), String.t() | nil) :: map() | nil
  def place(%__MODULE__{} = view, id), do: reference(view, "places", id)

  @doc """
  Looks up an aircraft by ID. Returns `nil` when the response does not
  name it.
  """
  @spec aircraft(t(), String.t() | nil) :: map() | nil
  def aircraft(%__MODULE__{} = view, id), do: reference(view, "aircraft", id)

  defp reference(_view, _kind, nil), do: nil

  defp reference(%__MODULE__{references: references}, kind, id) do
    references |> Map.get(kind, %{}) |> Map.get(id)
  end
end
