defmodule Duffel.Payments do
  @moduledoc """
  Pay for hold orders that were booked without immediate payment.

  See the [Duffel documentation](https://duffel.com/docs/api/v2/payments).
  """

  alias Duffel.{Client, Page}

  @path "/air/payments"

  @doc """
  Creates a payment for a hold order.

  ## Options

    * `:idempotency_key` - sets the `Idempotency-Key` header

  ## Examples

      Duffel.Payments.create(client, %{
        order_id: "ord_123",
        payment: %{type: "balance", currency: "GBP", amount: "30.20"}
      })

  """
  @spec create(Client.t(), map(), keyword()) :: {:ok, map()} | {:error, term()}
  def create(client, params, opts \\ []) do
    with {:ok, %{"data" => data}} <- Client.post(client, @path, params, opts) do
      {:ok, data}
    end
  end

  @doc """
  Retrieves a single payment by ID.
  """
  @spec get(Client.t(), String.t()) :: {:ok, map()} | {:error, term()}
  def get(client, id) when is_binary(id) do
    with {:ok, %{"data" => data}} <- Client.get(client, "#{@path}/#{id}") do
      {:ok, data}
    end
  end

  @doc """
  Lists one page of payments for an order.

  ## Parameters

    * `:order_id` - the order to list payments for (required)
    * `:limit` / `:after` / `:before` - pagination (see `Duffel.Page`)

  """
  @spec list(Client.t(), keyword() | map()) :: {:ok, Page.t()} | {:error, term()}
  def list(client, params) do
    Client.list(client, @path, params)
  end

  @doc """
  Lazily streams all payments for an order across pages.

  Takes the same parameters as `list/2`. Raises `Duffel.Error` if a page
  request fails.
  """
  @spec stream(Client.t(), keyword() | map()) :: Enumerable.t()
  def stream(client, params) do
    Client.stream(client, @path, params)
  end
end
