defmodule Duffel.Schema.Order do
  @moduledoc """
  A booked order.

  `slices` is a list of `Duffel.Schema.Slice` structs and `passengers` a list
  of `Duffel.Schema.Passenger` structs. The `owner` airline, `payment_status`,
  `services`, `documents`, `conditions`, `cancellation`, change history and
  `metadata` are kept as raw maps.
  """

  alias Duffel.Schema
  alias Duffel.Schema.{Passenger, Slice}

  defstruct [
    :id,
    :live_mode,
    :created_at,
    :booking_reference,
    :offer_id,
    :type,
    :payment_status,
    :total_amount,
    :total_currency,
    :base_amount,
    :base_currency,
    :tax_amount,
    :tax_currency,
    :owner,
    :conditions,
    :cancellation,
    :content,
    :metadata,
    :cancelled_at,
    :synced_at,
    :void_window_ends_at,
    slices: [],
    passengers: [],
    services: [],
    documents: [],
    airline_initiated_changes: [],
    changes: [],
    users: [],
    booking_references: [],
    available_actions: [],
    intended_payment_methods: []
  ]

  @type t :: %__MODULE__{
          id: String.t() | nil,
          live_mode: boolean() | nil,
          created_at: String.t() | nil,
          booking_reference: String.t() | nil,
          offer_id: String.t() | nil,
          type: String.t() | nil,
          payment_status: map() | nil,
          total_amount: String.t() | nil,
          total_currency: String.t() | nil,
          base_amount: String.t() | nil,
          base_currency: String.t() | nil,
          tax_amount: String.t() | nil,
          tax_currency: String.t() | nil,
          owner: map() | nil,
          conditions: map() | nil,
          cancellation: map() | nil,
          content: String.t() | nil,
          metadata: map() | nil,
          cancelled_at: String.t() | nil,
          synced_at: String.t() | nil,
          void_window_ends_at: String.t() | nil,
          slices: [Slice.t()],
          passengers: [Passenger.t()],
          services: [map()],
          documents: [map()],
          airline_initiated_changes: [map()],
          changes: [map()],
          users: [String.t()],
          booking_references: [map()],
          available_actions: [String.t()],
          intended_payment_methods: [String.t()]
        }

  @doc "Decodes a raw order map into a `#{inspect(__MODULE__)}`."
  @spec from_map(map() | t()) :: t()
  def from_map(%__MODULE__{} = decoded), do: decoded

  def from_map(map) when is_map(map) do
    %__MODULE__{
      id: map["id"],
      live_mode: map["live_mode"],
      created_at: map["created_at"],
      booking_reference: map["booking_reference"],
      offer_id: map["offer_id"],
      type: map["type"],
      payment_status: map["payment_status"],
      total_amount: map["total_amount"],
      total_currency: map["total_currency"],
      base_amount: map["base_amount"],
      base_currency: map["base_currency"],
      tax_amount: map["tax_amount"],
      tax_currency: map["tax_currency"],
      owner: map["owner"],
      conditions: map["conditions"],
      cancellation: map["cancellation"],
      content: map["content"],
      metadata: map["metadata"],
      cancelled_at: map["cancelled_at"],
      synced_at: map["synced_at"],
      void_window_ends_at: map["void_window_ends_at"],
      slices: Schema.cast_list(map["slices"], Slice),
      passengers: Schema.cast_list(map["passengers"], Passenger),
      services: map["services"] || [],
      documents: map["documents"] || [],
      airline_initiated_changes: map["airline_initiated_changes"] || [],
      changes: map["changes"] || [],
      users: map["users"] || [],
      booking_references: map["booking_references"] || [],
      available_actions: map["available_actions"] || [],
      intended_payment_methods: map["intended_payment_methods"] || []
    }
  end
end
