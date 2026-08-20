defmodule Duffel.BatchOfferRequests do
  @moduledoc """
  Batched flight search: create returns immediately with `total_batches`;
  poll `get/3` to receive offers batch by batch as airlines respond.

  `get/3` long-polls until the next batch is available or all batches
  have been returned.

  See the [Duffel documentation](https://duffel.com/docs/api/v2/batch-offer-requests).
  """

  alias Duffel.{Client, Error}

  @path "/air/batch_offer_requests"

  @doc """
  Creates a batch offer request.

  Takes the same search parameters as `Duffel.OfferRequests.create/3`.

  ## Options

    * `:params` - query string parameters, e.g. `params: [supplier_timeout: 10_000]`

  """
  @spec create(Client.t(), map(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def create(client, params, opts \\ []) do
    Client.post_data(client, @path, params, opts)
  end

  @doc """
  Long-polls for the next batch of offers.

  Call repeatedly until `remaining_batches` reaches zero.

  ## Options

    * `:params` - query string parameters. `view: "itineraries"` groups the
      offers into slices, itineraries and brands with shared airlines,
      places and aircraft in top-level reference maps, instead of the flat
      list of offers `view: "offers"` (the default) returns

  ## Examples

      Duffel.BatchOfferRequests.get(client, "brq_123", params: [view: "itineraries"])

  """
  @spec get(Client.t(), String.t(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def get(client, id, opts \\ []) when is_binary(id) do
    Client.get_data(client, "#{@path}/#{id}", opts)
  end
end
