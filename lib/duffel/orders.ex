defmodule Duffel.Orders do
  @moduledoc """
  Book flights by creating orders from offers, and manage existing orders.

  See the [Duffel documentation](https://duffel.com/docs/api/v2/orders).
  """

  alias Duffel.{Client, Page}

  @path "/air/orders"

  @doc """
  Creates an order from a selected offer.

  Pass `:idempotency_key` to guard against duplicate bookings on retries.

  ## Options

    * `:idempotency_key` - sets the `Idempotency-Key` header

  ## Examples

      Duffel.Orders.create(
        client,
        %{
          selected_offers: ["off_123"],
          passengers: [
            %{
              id: "pas_123",
              title: "ms",
              given_name: "Amelia",
              family_name: "Earhart",
              born_on: "1987-07-24",
              email: "amelia@duffel.com",
              phone_number: "+442080160508"
            }
          ],
          payments: [
            %{type: "balance", currency: "GBP", amount: "30.20"}
          ]
        },
        idempotency_key: "booking-123"
      )

  """
  @spec create(Client.t(), map(), keyword()) :: {:ok, map()} | {:error, term()}
  def create(client, params, opts \\ []) do
    with {:ok, %{"data" => data}} <- Client.post(client, @path, params, opts) do
      {:ok, data}
    end
  end

  @doc """
  Retrieves a single order by ID.
  """
  @spec get(Client.t(), String.t()) :: {:ok, map()} | {:error, term()}
  def get(client, id) when is_binary(id) do
    with {:ok, %{"data" => data}} <- Client.get(client, "#{@path}/#{id}") do
      {:ok, data}
    end
  end

  @doc """
  Lists one page of orders.

  ## Parameters

    * `:booking_reference` - filter by booking reference (exact match)
    * `:offer_id` - filter by the offer used at booking
    * `:awaiting_payment` - filter by payment status (boolean)
    * `:requires_action` - orders with unactioned airline-initiated changes
    * `:sort` - `"payment_required_by"`, `"total_amount"`, `"created_at"`
      or `"next_departure"`, prefix with `-` for descending
    * `:limit` / `:after` / `:before` - pagination (see `Duffel.Page`)

  See the Duffel documentation for the full set of filters
  (`owner_id[]`, `origin_id[]`, `passenger_name[]`, datetime ranges, ...).
  """
  @spec list(Client.t(), keyword() | map()) :: {:ok, Page.t()} | {:error, term()}
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
  @spec update(Client.t(), String.t(), map()) :: {:ok, map()} | {:error, term()}
  def update(client, id, params) when is_binary(id) do
    with {:ok, %{"data" => data}} <- Client.patch(client, "#{@path}/#{id}", params) do
      {:ok, data}
    end
  end

  @doc """
  Lists the services (e.g. extra bags, seats) available to add to an order.
  """
  @spec available_services(Client.t(), String.t()) :: {:ok, [map()]} | {:error, term()}
  def available_services(client, id) when is_binary(id) do
    with {:ok, %{"data" => data}} <-
           Client.get(client, "#{@path}/#{id}/available_services") do
      {:ok, data}
    end
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
          {:ok, map()} | {:error, term()}
  def add_services(client, id, params, opts \\ []) when is_binary(id) do
    with {:ok, %{"data" => data}} <-
           Client.post(client, "#{@path}/#{id}/services", params, opts) do
      {:ok, data}
    end
  end
end
