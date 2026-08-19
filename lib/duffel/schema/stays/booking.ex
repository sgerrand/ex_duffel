defmodule Duffel.Schema.Stays.Booking do
  @moduledoc """
  A booked stay.

  `accommodation` is a `Duffel.Schema.Stays.Accommodation` struct. `guests`,
  `key_collection` and `metadata` are kept as raw maps.
  """

  alias Duffel.Schema
  alias Duffel.Schema.Stays.Accommodation

  defstruct [
    :id,
    :live_mode,
    :reference,
    :status,
    :confirmed_at,
    :cancelled_at,
    :check_in_date,
    :check_out_date,
    :rooms,
    :email,
    :phone_number,
    :accommodation,
    :accommodation_special_requests,
    :loyalty_programme_account_number,
    :key_collection,
    :payment_status,
    :metadata,
    guests: [],
    users: []
  ]

  @type t :: %__MODULE__{
          id: String.t() | nil,
          live_mode: boolean() | nil,
          reference: String.t() | nil,
          status: String.t() | nil,
          confirmed_at: String.t() | nil,
          cancelled_at: String.t() | nil,
          check_in_date: String.t() | nil,
          check_out_date: String.t() | nil,
          rooms: integer() | nil,
          email: String.t() | nil,
          phone_number: String.t() | nil,
          accommodation: Accommodation.t() | nil,
          accommodation_special_requests: String.t() | nil,
          loyalty_programme_account_number: String.t() | nil,
          key_collection: map() | nil,
          payment_status: String.t() | nil,
          metadata: map() | nil,
          guests: [map()],
          users: [String.t()]
        }

  @doc "Decodes a raw stays booking map into a `#{inspect(__MODULE__)}`."
  @spec from_map(map()) :: t()
  def from_map(map) when is_map(map) do
    %__MODULE__{
      id: map["id"],
      live_mode: map["live_mode"],
      reference: map["reference"],
      status: map["status"],
      confirmed_at: map["confirmed_at"],
      cancelled_at: map["cancelled_at"],
      check_in_date: map["check_in_date"],
      check_out_date: map["check_out_date"],
      rooms: map["rooms"],
      email: map["email"],
      phone_number: map["phone_number"],
      accommodation: Schema.cast(map["accommodation"], Accommodation),
      accommodation_special_requests: map["accommodation_special_requests"],
      loyalty_programme_account_number: map["loyalty_programme_account_number"],
      key_collection: map["key_collection"],
      payment_status: map["payment_status"],
      metadata: map["metadata"],
      guests: map["guests"] || [],
      users: map["users"] || []
    }
  end
end
