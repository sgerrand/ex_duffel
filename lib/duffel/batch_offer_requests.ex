defmodule Duffel.BatchOfferRequests do
  @moduledoc """
  Batched flight search: create returns immediately with `total_batches`;
  poll `get/2` to receive offers batch by batch as airlines respond.

  `get/2` long-polls until the next batch is available or all batches
  have been returned.

  See the [Duffel documentation](https://duffel.com/docs/api/v2/batch-offer-requests).
  """

  alias Duffel.Client

  @path "/air/batch_offer_requests"

  @doc """
  Creates a batch offer request.

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
  Long-polls for the next batch of offers.

  Call repeatedly until `remaining_batches` reaches zero.
  """
  @spec get(Client.t(), String.t()) :: {:ok, map()} | {:error, term()}
  def get(client, id) when is_binary(id) do
    with {:ok, %{"data" => data}} <- Client.get(client, "#{@path}/#{id}") do
      {:ok, data}
    end
  end
end
