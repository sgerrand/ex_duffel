defmodule Duffel.Schema.Stays.SearchResult do
  @moduledoc """
  One accommodation returned by a stays search, with its cheapest rate.

  `accommodation` is a `Duffel.Schema.Stays.Accommodation` struct. `guests`
  is kept as a list of raw maps.
  """

  alias Duffel.Schema
  alias Duffel.Schema.Stays.Accommodation

  defstruct [
    :id,
    :check_in_date,
    :check_out_date,
    :rooms,
    :cheapest_rate_total_amount,
    :cheapest_rate_currency,
    :cheapest_rate_public_amount,
    :accommodation,
    guests: []
  ]

  @type t :: %__MODULE__{
          id: String.t() | nil,
          check_in_date: String.t() | nil,
          check_out_date: String.t() | nil,
          rooms: integer() | nil,
          cheapest_rate_total_amount: String.t() | nil,
          cheapest_rate_currency: String.t() | nil,
          cheapest_rate_public_amount: String.t() | nil,
          accommodation: Accommodation.t() | nil,
          guests: [map()]
        }

  @doc "Decodes a raw stays search result map into a `#{inspect(__MODULE__)}`."
  @spec from_map(map()) :: t()
  def from_map(map) when is_map(map) do
    %__MODULE__{
      id: map["id"],
      check_in_date: map["check_in_date"],
      check_out_date: map["check_out_date"],
      rooms: map["rooms"],
      cheapest_rate_total_amount: map["cheapest_rate_total_amount"],
      cheapest_rate_currency: map["cheapest_rate_currency"],
      cheapest_rate_public_amount: map["cheapest_rate_public_amount"],
      accommodation: Schema.cast(map["accommodation"], Accommodation),
      guests: map["guests"] || []
    }
  end
end
