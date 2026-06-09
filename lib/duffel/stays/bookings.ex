defmodule Duffel.Stays.Bookings do
  @moduledoc """
  Book accommodation from a quote, then manage and cancel the booking.

  See the [Duffel documentation](https://duffel.com/docs/api/v2/stays-bookings).
  """

  alias Duffel.{Client, Page}

  @path "/stays/bookings"

  @doc """
  Creates a booking from a quote.

  ## Options

    * `:idempotency_key` - sets the `Idempotency-Key` header

  ## Examples

      Duffel.Stays.Bookings.create(
        client,
        %{
          quote_id: "quo_123",
          guests: [%{given_name: "Amelia", family_name: "Earhart"}],
          email: "amelia@duffel.com",
          phone_number: "+442080160508"
        },
        idempotency_key: "stay-booking-1"
      )

  """
  @spec create(Client.t(), map(), keyword()) :: {:ok, map()} | {:error, term()}
  def create(client, params, opts \\ []) do
    with {:ok, %{"data" => data}} <- Client.post(client, @path, params, opts) do
      {:ok, data}
    end
  end

  @doc """
  Retrieves a single booking by ID.
  """
  @spec get(Client.t(), String.t()) :: {:ok, map()} | {:error, term()}
  def get(client, id) when is_binary(id) do
    with {:ok, %{"data" => data}} <- Client.get(client, "#{@path}/#{id}") do
      {:ok, data}
    end
  end

  @doc """
  Lists one page of bookings.

  ## Parameters

    * `:limit` / `:after` / `:before` - pagination (see `Duffel.Page`)

  """
  @spec list(Client.t(), keyword() | map()) :: {:ok, Page.t()} | {:error, term()}
  def list(client, params \\ []) do
    Client.list(client, @path, params)
  end

  @doc """
  Lazily streams all bookings across pages.

  Raises `Duffel.Error` if a page request fails.
  """
  @spec stream(Client.t(), keyword() | map()) :: Enumerable.t()
  def stream(client, params \\ []) do
    Client.stream(client, @path, params)
  end

  @doc """
  Updates a booking's metadata or the customer users allowed to manage it.

  ## Examples

      Duffel.Stays.Bookings.update(client, "bok_123", %{metadata: %{ref: "abc"}})

  """
  @spec update(Client.t(), String.t(), map()) :: {:ok, map()} | {:error, term()}
  def update(client, id, params) when is_binary(id) do
    with {:ok, %{"data" => data}} <- Client.patch(client, "#{@path}/#{id}", params) do
      {:ok, data}
    end
  end

  @doc """
  Cancels a booking.
  """
  @spec cancel(Client.t(), String.t()) :: {:ok, map()} | {:error, term()}
  def cancel(client, id) when is_binary(id) do
    with {:ok, %{"data" => data}} <-
           Client.post(client, "#{@path}/#{id}/actions/cancel", %{}) do
      {:ok, data}
    end
  end

  @doc """
  Creates payment instructions for a postpaid booking, providing the card
  the accommodation will charge.

  ## Examples

      Duffel.Stays.Bookings.create_payment_instruction(client, "bok_123", %{
        card_id: "tcd_123"
      })

  """
  @spec create_payment_instruction(Client.t(), String.t(), map()) ::
          {:ok, map()} | {:error, term()}
  def create_payment_instruction(client, id, params) when is_binary(id) do
    with {:ok, %{"data" => data}} <-
           Client.post(client, "#{@path}/#{id}/payment_instructions", params) do
      {:ok, data}
    end
  end
end
