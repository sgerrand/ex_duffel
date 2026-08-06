defmodule Duffel.Schema.Stays.Accommodation do
  @moduledoc """
  A property that can be booked.

  `rooms` is a list of `Duffel.Schema.Stays.Room` structs.
  `check_in_information`, `location`, `photos`, `amenities`, `brand`,
  `chain` and `key_collection` are kept as raw maps.
  """

  alias Duffel.Schema
  alias Duffel.Schema.Stays.Room

  defstruct [
    :id,
    :name,
    :description,
    :rating,
    :review_score,
    :email,
    :phone_number,
    :check_in_information,
    :location,
    :brand,
    :chain,
    :key_collection,
    :supported_loyalty_programme,
    photos: [],
    amenities: [],
    rooms: []
  ]

  @type t :: %__MODULE__{
          id: String.t() | nil,
          name: String.t() | nil,
          description: String.t() | nil,
          rating: integer() | nil,
          review_score: number() | nil,
          email: String.t() | nil,
          phone_number: String.t() | nil,
          check_in_information: map() | nil,
          location: map() | nil,
          brand: map() | nil,
          chain: map() | nil,
          key_collection: map() | nil,
          supported_loyalty_programme: String.t() | nil,
          photos: [map()],
          amenities: [map()],
          rooms: [Room.t()]
        }

  @doc "Decodes a raw stays accommodation map into a `#{inspect(__MODULE__)}`."
  @spec from_map(map()) :: t()
  def from_map(map) when is_map(map) do
    %__MODULE__{
      id: map["id"],
      name: map["name"],
      description: map["description"],
      rating: map["rating"],
      review_score: map["review_score"],
      email: map["email"],
      phone_number: map["phone_number"],
      check_in_information: map["check_in_information"],
      location: map["location"],
      brand: map["brand"],
      chain: map["chain"],
      key_collection: map["key_collection"],
      supported_loyalty_programme: map["supported_loyalty_programme"],
      photos: map["photos"] || [],
      amenities: map["amenities"] || [],
      rooms: Schema.cast_list(map["rooms"], Room)
    }
  end
end
