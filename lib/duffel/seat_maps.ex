defmodule Duffel.SeatMaps do
  @moduledoc """
  Retrieve seat maps for an offer to build a seat selection UI.

  One seat map is returned per segment. Not paginated.

  See the [Duffel documentation](https://duffel.com/docs/api/v2/seat-maps).
  """

  alias Duffel.Client

  @path "/air/seat_maps"

  @doc """
  Lists the seat maps for an offer.

  ## Parameters

    * `:offer_id` - the offer to fetch seat maps for (required)

  ## Examples

      Duffel.SeatMaps.list(client, offer_id: "off_123")

  """
  @spec list(Client.t(), keyword() | map()) :: {:ok, [map()]} | {:error, term()}
  def list(client, params) do
    with {:ok, %{"data" => data}} <- Client.get(client, @path, params: Map.new(params)) do
      {:ok, data}
    end
  end
end
