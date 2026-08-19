defmodule Duffel.Schema.Stays.Rate do
  @moduledoc """
  A bookable rate for a room.

  `cancellation_timeline`, `conditions` and `loyalty_programme` are kept as
  raw maps.
  """

  defstruct [
    :id,
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
    :public_amount,
    :public_currency,
    :board_type,
    :payment_type,
    :negotiated_rate_code,
    :source,
    :supplier,
    :quantity_available,
    :loyalty_programme,
    available_payment_methods: [],
    cancellation_timeline: [],
    conditions: []
  ]

  @type t :: %__MODULE__{
          id: String.t() | nil,
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
          public_amount: String.t() | nil,
          public_currency: String.t() | nil,
          board_type: String.t() | nil,
          payment_type: String.t() | nil,
          negotiated_rate_code: String.t() | nil,
          source: String.t() | nil,
          supplier: String.t() | nil,
          quantity_available: integer() | nil,
          loyalty_programme: map() | nil,
          available_payment_methods: [String.t()],
          cancellation_timeline: [map()],
          conditions: [map()]
        }

  @doc "Decodes a raw stays rate map into a `#{inspect(__MODULE__)}`."
  @spec from_map(map() | t()) :: t()
  def from_map(%__MODULE__{} = decoded), do: decoded

  def from_map(map) when is_map(map) do
    %__MODULE__{
      id: map["id"],
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
      public_amount: map["public_amount"],
      public_currency: map["public_currency"],
      board_type: map["board_type"],
      payment_type: map["payment_type"],
      negotiated_rate_code: map["negotiated_rate_code"],
      source: map["source"],
      supplier: map["supplier"],
      quantity_available: map["quantity_available"],
      loyalty_programme: map["loyalty_programme"],
      available_payment_methods: map["available_payment_methods"] || [],
      cancellation_timeline: map["cancellation_timeline"] || [],
      conditions: map["conditions"] || []
    }
  end
end
