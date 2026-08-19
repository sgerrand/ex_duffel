defmodule Duffel.Cards do
  @moduledoc """
  Tokenise cards for use in payments and 3DS sessions.

  Cards are served from the PCI-scoped host `api.duffel.cards`, not the
  main API host. The host is configurable via `:cards_base_url` on the
  client.

  A card token is single-use and short-lived: create it immediately
  before the payment that consumes it.

  See the [Duffel documentation](https://duffel.com/docs/api/v2/cards).
  """

  alias Duffel.{Client, Error}

  @path "/payments/cards"

  @doc """
  Tokenises a card, returning a card ID.

  ## Options

    * `:idempotency_key` - value for the `Idempotency-Key` header. A key is
      generated when you do not pass one (see `Duffel.Client.post/4`).

  ## Examples

      Duffel.Cards.create(client, %{
        number: "4242424242424242",
        expiry_month: "03",
        expiry_year: "30",
        cvc: "737",
        name: "Amelia Earhart",
        address_postal_code: "EC2A 4RQ",
        address_country_code: "GB"
      })

  """
  @spec create(Client.t(), map(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def create(client, params, opts \\ []) do
    opts = Keyword.put_new(opts, :base_url, client.cards_base_url)

    Client.post_data(client, @path, params, opts)
  end

  @doc """
  Deletes a card token.
  """
  @spec delete(Client.t(), String.t()) :: :ok | {:error, Error.t()}
  def delete(client, id) when is_binary(id) do
    client |> Client.delete("#{@path}/#{id}", base_url: client.cards_base_url) |> Client.discard()
  end
end
