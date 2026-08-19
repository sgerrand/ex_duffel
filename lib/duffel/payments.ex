defmodule Duffel.Payments do
  @moduledoc """
  Pay for hold orders that were booked without immediate payment.

  See the [Duffel documentation](https://duffel.com/docs/api/v2/payments).
  """

  alias Duffel.{Client, Error, Page}

  @path "/air/payments"

  @doc """
  Creates a payment for a hold order.

  ## Options

    * `:idempotency_key` - value for the `Idempotency-Key` header. A key is
      generated when you do not pass one (see `Duffel.Client.post/4`).

  ## Examples

      Duffel.Payments.create(client, %{
        order_id: "ord_123",
        payment: %{type: "balance", currency: "GBP", amount: "30.20"}
      })

  """
  @spec create(Client.t(), map(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def create(client, params, opts \\ []) do
    client |> Client.post(@path, params, opts) |> Client.unwrap()
  end

  @doc """
  Retrieves a single payment by ID.
  """
  @spec get(Client.t(), String.t()) :: {:ok, map()} | {:error, Error.t()}
  def get(client, id) when is_binary(id) do
    client |> Client.get("#{@path}/#{id}") |> Client.unwrap()
  end

  @doc """
  Lists one page of payments.

  ## Parameters

    * `:order_id` - filter payments by order
    * `:limit` / `:after` / `:before` - pagination (see `Duffel.Page`)

  """
  @spec list(Client.t(), keyword() | map()) :: {:ok, Page.t()} | {:error, Error.t()}
  def list(client, params \\ []) do
    Client.list(client, @path, params)
  end

  @doc """
  Lazily streams all payments across pages.

  Takes the same parameters as `list/2`. Raises `Duffel.Error` if a page
  request fails.
  """
  @spec stream(Client.t(), keyword() | map()) :: Enumerable.t()
  def stream(client, params \\ []) do
    Client.stream(client, @path, params)
  end
end
