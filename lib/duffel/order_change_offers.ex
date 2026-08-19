defmodule Duffel.OrderChangeOffers do
  @moduledoc """
  Retrieve the offers returned by an order change request.

  See the [Duffel documentation](https://duffel.com/docs/api/v2/order-change-offers).
  """

  alias Duffel.{Client, Error, Page}

  @path "/air/order_change_offers"

  @doc """
  Lists one page of order change offers.

  ## Parameters

    * `:order_change_request_id` - the change request to list offers
      for (required)
    * `:sort` - `"change_total_amount"` or `"total_duration"`, prefix
      with `-` for descending
    * `:max_connections` - maximum number of connections (default 1)
    * `:limit` / `:after` / `:before` - pagination (see `Duffel.Page`)

  """
  @spec list(Client.t(), keyword() | map()) :: {:ok, Page.t()} | {:error, Error.t()}
  def list(client, params) do
    Client.list(client, @path, params)
  end

  @doc """
  Lazily streams all order change offers across pages.

  Takes the same parameters as `list/2`. Raises `Duffel.Error` if a page
  request fails.
  """
  @spec stream(Client.t(), keyword() | map()) :: Enumerable.t()
  def stream(client, params) do
    Client.stream(client, @path, params)
  end

  @doc """
  Retrieves a single order change offer by ID.
  """
  @spec get(Client.t(), String.t()) :: {:ok, map()} | {:error, Error.t()}
  def get(client, id) when is_binary(id) do
    client |> Client.get("#{@path}/#{id}") |> Client.unwrap()
  end
end
