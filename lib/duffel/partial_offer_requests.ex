defmodule Duffel.PartialOfferRequests do
  @moduledoc """
  Multi-step flight search: offers are returned per slice independently.

  Select one partial offer per slice, then fetch the full fares for the
  combination with `fares/3`.

  See the [Duffel documentation](https://duffel.com/docs/api/v2/partial-offer-requests).
  """

  alias Duffel.Client

  @path "/air/partial_offer_requests"

  @doc """
  Creates a partial offer request.

  Takes the same search parameters as `Duffel.OfferRequests.create/3`.

  ## Options

    * `:params` - query string parameters, e.g. `params: [supplier_timeout: 10_000]`

  """
  @spec create(Client.t(), map(), keyword()) :: {:ok, map()} | {:error, term()}
  def create(client, params, opts \\ []) do
    with {:ok, %{"data" => data}} <- Client.post(client, @path, params, opts) do
      {:ok, data}
    end
  end

  @doc """
  Retrieves a partial offer request.

  Pass `:selected_partial_offers` (a list of partial offer IDs already
  selected for previous slices) to get offers for the next slice.

  ## Examples

      Duffel.PartialOfferRequests.get(client, "prq_123",
        selected_partial_offers: ["off_1", "off_2"]
      )

  """
  @spec get(Client.t(), String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def get(client, id, opts \\ []) when is_binary(id) do
    params = selected_partial_offer_params(Keyword.get(opts, :selected_partial_offers, []))

    with {:ok, %{"data" => data}} <- Client.get(client, "#{@path}/#{id}", params: params) do
      {:ok, data}
    end
  end

  @doc """
  Fetches the full fares for one selected partial offer per slice.

  ## Examples

      Duffel.PartialOfferRequests.fares(client, "prq_123", ["off_1", "off_2"])

  """
  @spec fares(Client.t(), String.t(), [String.t()]) :: {:ok, map()} | {:error, term()}
  def fares(client, id, selected_partial_offers)
      when is_binary(id) and is_list(selected_partial_offers) do
    params = selected_partial_offer_params(selected_partial_offers)

    with {:ok, %{"data" => data}} <-
           Client.get(client, "#{@path}/#{id}/fares", params: params) do
      {:ok, data}
    end
  end

  defp selected_partial_offer_params(ids) do
    for id <- ids, do: {"selected_partial_offer[]", id}
  end
end
