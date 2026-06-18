defmodule Duffel.Schema.Offer do
  @moduledoc """
  A bookable offer returned by a search.

  `slices` is a list of `Duffel.Schema.Slice` structs and `passengers` a list
  of `Duffel.Schema.Passenger` structs. The `owner` airline,
  `payment_requirements`, `available_services`, `conditions` and
  `private_fares` are kept as raw maps.
  """

  alias Duffel.Schema
  alias Duffel.Schema.{Passenger, Slice}

  defstruct [
    :id,
    :live_mode,
    :created_at,
    :updated_at,
    :expires_at,
    :partial,
    :total_amount,
    :total_currency,
    :base_amount,
    :base_currency,
    :tax_amount,
    :tax_currency,
    :total_emissions_kg,
    :owner,
    :payment_requirements,
    :conditions,
    :passenger_identity_documents_required,
    slices: [],
    passengers: [],
    available_services: [],
    supported_passenger_identity_document_types: [],
    private_fares: []
  ]

  @type t :: %__MODULE__{
          id: String.t() | nil,
          live_mode: boolean() | nil,
          created_at: String.t() | nil,
          updated_at: String.t() | nil,
          expires_at: String.t() | nil,
          partial: boolean() | nil,
          total_amount: String.t() | nil,
          total_currency: String.t() | nil,
          base_amount: String.t() | nil,
          base_currency: String.t() | nil,
          tax_amount: String.t() | nil,
          tax_currency: String.t() | nil,
          total_emissions_kg: String.t() | nil,
          owner: map() | nil,
          payment_requirements: map() | nil,
          conditions: map() | nil,
          passenger_identity_documents_required: boolean() | nil,
          slices: [Slice.t()],
          passengers: [Passenger.t()],
          available_services: [map()],
          supported_passenger_identity_document_types: [String.t()],
          private_fares: [map()]
        }

  @doc "Decodes a raw offer map into a `#{inspect(__MODULE__)}`."
  @spec from_map(map()) :: t()
  def from_map(map) when is_map(map) do
    %__MODULE__{
      id: map["id"],
      live_mode: map["live_mode"],
      created_at: map["created_at"],
      updated_at: map["updated_at"],
      expires_at: map["expires_at"],
      partial: map["partial"],
      total_amount: map["total_amount"],
      total_currency: map["total_currency"],
      base_amount: map["base_amount"],
      base_currency: map["base_currency"],
      tax_amount: map["tax_amount"],
      tax_currency: map["tax_currency"],
      total_emissions_kg: map["total_emissions_kg"],
      owner: map["owner"],
      payment_requirements: map["payment_requirements"],
      conditions: map["conditions"],
      passenger_identity_documents_required: map["passenger_identity_documents_required"],
      slices: Schema.cast_list(map["slices"], Slice),
      passengers: Schema.cast_list(map["passengers"], Passenger),
      available_services: map["available_services"] || [],
      supported_passenger_identity_document_types:
        map["supported_passenger_identity_document_types"] || [],
      private_fares: map["private_fares"] || []
    }
  end
end
