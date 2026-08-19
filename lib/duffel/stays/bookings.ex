defmodule Duffel.Stays.Bookings do
  @moduledoc """
  Book accommodation from a quote, then manage and cancel the booking.

  See the [Duffel documentation](https://duffel.com/docs/api/v2/stays-bookings).
  """

  alias Duffel.{Client, Error, Page}

  @path "/stays/bookings"

  @doc """
  Creates a booking from a quote.

  ## Options

    * `:idempotency_key` - value for the `Idempotency-Key` header. A key is
      generated when you do not pass one (see `Duffel.Client.post/4`).

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
  @spec create(Client.t(), map(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def create(client, params, opts \\ []) do
    Client.post_data(client, @path, params, opts)
  end

  @doc """
  Retrieves a single booking by ID.
  """
  @spec get(Client.t(), String.t()) :: {:ok, map()} | {:error, Error.t()}
  def get(client, id) when is_binary(id) do
    Client.get_data(client, "#{@path}/#{id}")
  end

  @doc """
  Lists one page of bookings.

  ## Parameters

    * `:limit` / `:after` / `:before` - pagination (see `Duffel.Page`)

  """
  @spec list(Client.t(), keyword() | map()) :: {:ok, Page.t()} | {:error, Error.t()}
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
  @spec update(Client.t(), String.t(), map()) :: {:ok, map()} | {:error, Error.t()}
  def update(client, id, params) when is_binary(id) do
    Client.patch_data(client, "#{@path}/#{id}", params)
  end

  @doc """
  Cancels a booking.
  """
  @spec cancel(Client.t(), String.t()) :: {:ok, map()} | {:error, Error.t()}
  def cancel(client, id) when is_binary(id) do
    Client.post_data(client, "#{@path}/#{id}/actions/cancel", %{})
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
          {:ok, map()} | {:error, Error.t()}
  def create_payment_instruction(client, id, params) when is_binary(id) do
    Client.post_data(client, "#{@path}/#{id}/payment_instructions", params)
  end
end
