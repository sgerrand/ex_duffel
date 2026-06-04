defmodule Duffel.OrderChangeRequests do
  @moduledoc """
  Request changes to an existing order's slices.

  The change flow: create an order change request describing slices to
  add/remove, pick from the resulting `Duffel.OrderChangeOffers`, then
  create and confirm a `Duffel.OrderChanges`.

  See the [Duffel documentation](https://duffel.com/docs/api/v2/order-change-requests).
  """

  alias Duffel.Client

  @path "/air/order_change_requests"

  @doc """
  Creates an order change request.

  ## Examples

      Duffel.OrderChangeRequests.create(client, %{
        order_id: "ord_123",
        slices: %{
          remove: [%{slice_id: "sli_123"}],
          add: [
            %{
              origin: "LHR",
              destination: "JFK",
              departure_date: "2026-07-14",
              cabin_class: "economy"
            }
          ]
        }
      })

  """
  @spec create(Client.t(), map(), keyword()) :: {:ok, map()} | {:error, term()}
  def create(client, params, opts \\ []) do
    with {:ok, %{"data" => data}} <- Client.post(client, @path, params, opts) do
      {:ok, data}
    end
  end

  @doc """
  Retrieves a single order change request by ID.
  """
  @spec get(Client.t(), String.t()) :: {:ok, map()} | {:error, term()}
  def get(client, id) when is_binary(id) do
    with {:ok, %{"data" => data}} <- Client.get(client, "#{@path}/#{id}") do
      {:ok, data}
    end
  end
end
