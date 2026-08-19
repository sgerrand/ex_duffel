defmodule Duffel.Schema.Stays.Room do
  @moduledoc """
  A room within an accommodation, with its bookable rates.

  `rates` is a list of `Duffel.Schema.Stays.Rate` structs. `photos` and
  `beds` are kept as raw maps.
  """

  alias Duffel.Schema
  alias Duffel.Schema.Stays.Rate

  defstruct [:name, photos: [], beds: [], rates: []]

  @type t :: %__MODULE__{
          name: String.t() | nil,
          photos: [map()],
          beds: [map()],
          rates: [Rate.t()]
        }

  @doc "Decodes a raw stays room map into a `#{inspect(__MODULE__)}`."
  @spec from_map(map() | t()) :: t()
  def from_map(%__MODULE__{} = decoded), do: decoded

  def from_map(map) when is_map(map) do
    %__MODULE__{
      name: map["name"],
      photos: map["photos"] || [],
      beds: map["beds"] || [],
      rates: Schema.cast_list(map["rates"], Rate)
    }
  end
end
