defmodule Duffel.Schema.Passenger do
  @moduledoc """
  A passenger on an offer request, offer or order.

  The fields are a superset of the offer-side passenger (`id`, `type`, `age`)
  and the booked order passenger (`title`, `gender`, `born_on`, contact
  details). Fields that do not apply to a given response are `nil`.

  `loyalty_programme_accounts` and `identity_documents` are kept as raw maps.
  """

  defstruct [
    :id,
    :type,
    :age,
    :given_name,
    :family_name,
    :title,
    :gender,
    :born_on,
    :email,
    :phone_number,
    :infant_passenger_id,
    :fare_type,
    :user_id,
    loyalty_programme_accounts: [],
    identity_documents: []
  ]

  @type t :: %__MODULE__{
          id: String.t() | nil,
          type: String.t() | nil,
          age: integer() | nil,
          given_name: String.t() | nil,
          family_name: String.t() | nil,
          title: String.t() | nil,
          gender: String.t() | nil,
          born_on: String.t() | nil,
          email: String.t() | nil,
          phone_number: String.t() | nil,
          infant_passenger_id: String.t() | nil,
          fare_type: String.t() | nil,
          user_id: String.t() | nil,
          loyalty_programme_accounts: [map()],
          identity_documents: [map()]
        }

  @doc "Decodes a raw passenger map into a `#{inspect(__MODULE__)}`."
  @spec from_map(map()) :: t()
  def from_map(map) when is_map(map) do
    %__MODULE__{
      id: map["id"],
      type: map["type"],
      age: map["age"],
      given_name: map["given_name"],
      family_name: map["family_name"],
      title: map["title"],
      gender: map["gender"],
      born_on: map["born_on"],
      email: map["email"],
      phone_number: map["phone_number"],
      infant_passenger_id: map["infant_passenger_id"],
      fare_type: map["fare_type"],
      user_id: map["user_id"],
      loyalty_programme_accounts: map["loyalty_programme_accounts"] || [],
      identity_documents: map["identity_documents"] || []
    }
  end
end
