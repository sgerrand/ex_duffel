defmodule Duffel.Orders do
  @moduledoc """
  Book flights by creating orders from offers, and manage existing orders.

  See the [Duffel documentation](https://duffel.com/docs/api/v2/orders).
  """

  alias Duffel.{Client, Error, Page}

  @path "/air/orders"

  @doc """
  Creates an order from a selected offer.

  Build the params by hand or with `Duffel.Orders.CreateParams`.

  A generated `Idempotency-Key` stops the automatic retry of a failed
  request booking twice. Pass your own key when your application may
  retry the same booking itself, so the second attempt reuses it.

  ## Options

    * `:idempotency_key` - value for the `Idempotency-Key` header. A key is
      generated when you do not pass one (see `Duffel.Client.post/4`).

  ## Examples

      alias Duffel.Orders.CreateParams

      params =
        CreateParams.new(
          selected_offers: ["off_123"],
          passengers: [
            CreateParams.passenger(
              id: "pas_123",
              title: "ms",
              given_name: "Amelia",
              family_name: "Earhart",
              gender: "f",
              born_on: "1987-07-24",
              email: "amelia@duffel.com",
              phone_number: "+442080160508"
            )
          ],
          payments: [CreateParams.payment(type: "balance", currency: "GBP", amount: "30.20")]
        )

      Duffel.Orders.create(client, params, idempotency_key: "booking-123")

  """
  @spec create(Client.t(), map(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def create(client, params, opts \\ []) do
    client |> Client.post(@path, params, opts) |> Client.unwrap()
  end

  @doc """
  Retrieves a single order by ID.
  """
  @spec get(Client.t(), String.t()) :: {:ok, map()} | {:error, Error.t()}
  def get(client, id) when is_binary(id) do
    client |> Client.get("#{@path}/#{id}") |> Client.unwrap()
  end

  @doc """
  Lists one page of orders.

  ## Parameters

    * `:booking_reference` - filter by airline booking reference (PNR)
    * `:awaiting_payment` - filter hold orders awaiting payment (boolean)
    * `:requires_action` - orders with unactioned airline-initiated changes
    * `"passenger_name[]"` - filter by passenger name
    * `:sort` - `"payment_required_by"`, `"created_at"` or
      `"next_departure"`, prefix with `-` for descending
    * `:limit` / `:after` / `:before` - pagination (see `Duffel.Page`)
  """
  @spec list(Client.t(), keyword() | map()) :: {:ok, Page.t()} | {:error, Error.t()}
  def list(client, params \\ []) do
    Client.list(client, @path, params)
  end

  @doc """
  Lazily streams all orders across pages.

  Takes the same parameters as `list/2`. Raises `Duffel.Error` if a page
  request fails.
  """
  @spec stream(Client.t(), keyword() | map()) :: Enumerable.t()
  def stream(client, params \\ []) do
    Client.stream(client, @path, params)
  end

  @doc """
  Updates a single order. Only `metadata` is updatable.

  ## Examples

      Duffel.Orders.update(client, "ord_123", %{metadata: %{customer_id: "123"}})

  """
  @spec update(Client.t(), String.t(), map()) :: {:ok, map()} | {:error, Error.t()}
  def update(client, id, params) when is_binary(id) do
    client |> Client.patch("#{@path}/#{id}", params) |> Client.unwrap()
  end

  @doc """
  Re-prices an unpaid (hold) order with the airline and returns the
  updated order.
  """
  @spec price(Client.t(), String.t()) :: {:ok, map()} | {:error, Error.t()}
  def price(client, id) when is_binary(id) do
    client |> Client.post("#{@path}/#{id}/actions/price", %{}) |> Client.unwrap()
  end

  @doc """
  Lists the services (e.g. extra bags, seats) available to add to an order.
  """
  @spec available_services(Client.t(), String.t()) :: {:ok, [map()]} | {:error, Error.t()}
  def available_services(client, id) when is_binary(id) do
    client |> Client.get("#{@path}/#{id}/available_services") |> Client.unwrap()
  end

  @doc """
  Adds services to an existing order, paying for them at the same time.

  ## Examples

      Duffel.Orders.add_services(client, "ord_123", %{
        add_services: [%{id: "ase_123", quantity: 1}],
        payment: %{type: "balance", currency: "GBP", amount: "15.00"}
      })

  """
  @spec add_services(Client.t(), String.t(), map(), keyword()) ::
          {:ok, map()} | {:error, Error.t()}
  def add_services(client, id, params, opts \\ []) when is_binary(id) do
    client |> Client.post("#{@path}/#{id}/services", params, opts) |> Client.unwrap()
  end
end
