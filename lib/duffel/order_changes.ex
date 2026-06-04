defmodule Duffel.OrderChanges do
  @moduledoc """
  Apply a selected order change offer to an order: create a pending
  order change, then confirm it (with payment if `change_total_amount`
  is positive).

  See the [Duffel documentation](https://duffel.com/docs/api/v2/order-changes).
  """

  alias Duffel.Client

  @path "/air/order_changes"

  @doc """
  Creates a pending order change from a selected order change offer.

  ## Examples

      Duffel.OrderChanges.create(client, %{selected_order_change_offer: "oco_123"})

  """
  @spec create(Client.t(), map(), keyword()) :: {:ok, map()} | {:error, term()}
  def create(client, params, opts \\ []) do
    with {:ok, %{"data" => data}} <- Client.post(client, @path, params, opts) do
      {:ok, data}
    end
  end

  @doc """
  Confirms a pending order change. This applies the change to the order
  and cannot be undone.

  `params` must include a `payment` when the change's
  `change_total_amount` is greater than zero; it may be omitted when the
  amount is zero or negative (refunds go to `refund_to`).

  ## Examples

      Duffel.OrderChanges.confirm(client, "oce_123", %{
        payment: %{type: "balance", currency: "GBP", amount: "125.00"}
      })

  """
  @spec confirm(Client.t(), String.t(), map(), keyword()) :: {:ok, map()} | {:error, term()}
  def confirm(client, id, params \\ %{}, opts \\ []) when is_binary(id) do
    with {:ok, %{"data" => data}} <-
           Client.post(client, "#{@path}/#{id}/actions/confirm", params, opts) do
      {:ok, data}
    end
  end

  @doc """
  Retrieves a single order change by ID.
  """
  @spec get(Client.t(), String.t()) :: {:ok, map()} | {:error, term()}
  def get(client, id) when is_binary(id) do
    with {:ok, %{"data" => data}} <- Client.get(client, "#{@path}/#{id}") do
      {:ok, data}
    end
  end
end
