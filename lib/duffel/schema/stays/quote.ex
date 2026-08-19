defmodule Duffel.Schema.Stays.Quote do
  @moduledoc """
  A confirmed price for a rate, ready to book.

  `accommodation` is a `Duffel.Schema.Stays.Accommodation` struct and
  `rate` a `Duffel.Schema.Stays.Rate` struct. `guests` is kept as a list of
  raw maps.
  """

  alias Duffel.Schema
  alias Duffel.Schema.Stays.{Accommodation, Rate}

  defstruct [
    :id,
    :live_mode,
    :check_in_date,
    :check_out_date,
    :rooms,
    :total_amount,
    :total_currency,
    :base_amount,
    :base_currency,
    :tax_amount,
    :tax_currency,
    :fee_amount,
    :fee_currency,
    :due_at_accommodation_amount,
    :due_at_accommodation_currency,
    :accommodation,
    :rate,
    :supported_loyalty_programme,
    guests: []
  ]

  @type t :: %__MODULE__{
          id: String.t() | nil,
          live_mode: boolean() | nil,
          check_in_date: String.t() | nil,
          check_out_date: String.t() | nil,
          rooms: integer() | nil,
          total_amount: String.t() | nil,
          total_currency: String.t() | nil,
          base_amount: String.t() | nil,
          base_currency: String.t() | nil,
          tax_amount: String.t() | nil,
          tax_currency: String.t() | nil,
          fee_amount: String.t() | nil,
          fee_currency: String.t() | nil,
          due_at_accommodation_amount: String.t() | nil,
          due_at_accommodation_currency: String.t() | nil,
          accommodation: Accommodation.t() | nil,
          rate: Rate.t() | nil,
          supported_loyalty_programme: String.t() | nil,
          guests: [map()]
        }

  @doc "Decodes a raw stays quote map into a `#{inspect(__MODULE__)}`."
  @spec from_map(map() | t()) :: t()
  def from_map(%__MODULE__{} = decoded), do: decoded

  def from_map(map) when is_map(map) do
    %__MODULE__{
      id: map["id"],
      live_mode: map["live_mode"],
      check_in_date: map["check_in_date"],
      check_out_date: map["check_out_date"],
      rooms: map["rooms"],
      total_amount: map["total_amount"],
      total_currency: map["total_currency"],
      base_amount: map["base_amount"],
      base_currency: map["base_currency"],
      tax_amount: map["tax_amount"],
      tax_currency: map["tax_currency"],
      fee_amount: map["fee_amount"],
      fee_currency: map["fee_currency"],
      due_at_accommodation_amount: map["due_at_accommodation_amount"],
      due_at_accommodation_currency: map["due_at_accommodation_currency"],
      accommodation: Schema.cast(map["accommodation"], Accommodation),
      rate: Schema.cast(map["rate"], Rate),
      supported_loyalty_programme: map["supported_loyalty_programme"],
      guests: map["guests"] || []
    }
  end
end
