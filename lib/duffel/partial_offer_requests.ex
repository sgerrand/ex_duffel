defmodule Duffel.PartialOfferRequests do
  @moduledoc """
  Multi-step flight search: offers are returned per slice independently.

  Select one partial offer per slice, then fetch the full fares for the
  combination with `fares/3`.

  See the [Duffel documentation](https://duffel.com/docs/api/v2/partial-offer-requests).
  """

  alias Duffel.{Client, Error}

  @path "/air/partial_offer_requests"

  @doc """
  Creates a partial offer request.

  Takes the same search parameters as `Duffel.OfferRequests.create/3`.

  ## Options

    * `:params` - query string parameters, e.g. `params: [supplier_timeout: 10_000]`

  """
  @spec create(Client.t(), map(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def create(client, params, opts \\ []) do
    Client.post_data(client, @path, params, opts)
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
  @spec get(Client.t(), String.t(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def get(client, id, opts \\ []) when is_binary(id) do
    path =
      append_selected_partial_offers(
        "#{@path}/#{id}",
        Keyword.get(opts, :selected_partial_offers, [])
      )

    Client.get_data(client, path)
  end

  @doc """
  Fetches the full fares for one selected partial offer per slice.

  ## Examples

      Duffel.PartialOfferRequests.fares(client, "prq_123", ["off_1", "off_2"])

  """
  @spec fares(Client.t(), String.t(), [String.t()]) :: {:ok, map()} | {:error, Error.t()}
  def fares(client, id, selected_partial_offers)
      when is_binary(id) and is_list(selected_partial_offers) do
    path = append_selected_partial_offers("#{@path}/#{id}/fares", selected_partial_offers)

    Client.get_data(client, path)
  end

  # `selected_partial_offer[]` repeats once per selected slice. Req's `:params`
  # option keeps only the last value for a repeated key, so the query string is
  # built into the path here instead.
  defp append_selected_partial_offers(path, []), do: path

  defp append_selected_partial_offers(path, ids) do
    query = URI.encode_query(for id <- ids, do: {"selected_partial_offer[]", id})
    path <> "?" <> query
  end
end
