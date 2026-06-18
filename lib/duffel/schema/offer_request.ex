defmodule Duffel.Schema.OfferRequest do
  @moduledoc """
  A search for flights.

  `offers` is a list of `Duffel.Schema.Offer` structs and `passengers` a list
  of `Duffel.Schema.Passenger` structs. `slices` here are the raw search
  criteria (origin, destination, date) — for full leg detail use the slices on
  an offer.
  """

  alias Duffel.Schema
  alias Duffel.Schema.{Offer, Passenger}

  defstruct [
    :id,
    :live_mode,
    :created_at,
    :cabin_class,
    :client_key,
    slices: [],
    passengers: [],
    offers: []
  ]

  @type t :: %__MODULE__{
          id: String.t() | nil,
          live_mode: boolean() | nil,
          created_at: String.t() | nil,
          cabin_class: String.t() | nil,
          client_key: String.t() | nil,
          slices: [map()],
          passengers: [Passenger.t()],
          offers: [Offer.t()]
        }

  @doc "Decodes a raw offer request map into a `#{inspect(__MODULE__)}`."
  @spec from_map(map()) :: t()
  def from_map(map) when is_map(map) do
    %__MODULE__{
      id: map["id"],
      live_mode: map["live_mode"],
      created_at: map["created_at"],
      cabin_class: map["cabin_class"],
      client_key: map["client_key"],
      slices: map["slices"] || [],
      passengers: Schema.cast_list(map["passengers"], Passenger),
      offers: Schema.cast_list(map["offers"], Offer)
    }
  end
end
