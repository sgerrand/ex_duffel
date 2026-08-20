defmodule Duffel.Offers do
  @moduledoc """
  Retrieve the offers returned by an offer request.

  An offer is a flight option (price, itinerary, conditions) that can be
  booked by creating an order.

  See the [Duffel documentation](https://duffel.com/docs/api/v2/offers).
  """

  alias Duffel.{Client, Error, Page}

  @path "/air/offers"

  @doc """
  Lists one page of offers for an offer request.

  ## Parameters

    * `:offer_request_id` - the offer request to list offers for (required)
    * `:sort` - `"total_amount"` or `"total_duration"`, prefix with `-`
      for descending
    * `:max_connections` - maximum number of connections (default 1)
    * `:limit` / `:after` / `:before` - pagination (see `Duffel.Page`)

  ## Examples

      Duffel.Offers.list(client, offer_request_id: "orq_123", sort: "total_amount")

  """
  @spec list(Client.t(), keyword() | map()) :: {:ok, Page.t()} | {:error, Error.t()}
  def list(client, params) do
    Client.list(client, @path, params)
  end

  @doc """
  Lazily streams all offers for an offer request across pages.

  Takes the same parameters as `list/2`. Raises `Duffel.Error` if a page
  request fails.
  """
  @spec stream(Client.t(), keyword() | map()) :: Enumerable.t()
  def stream(client, params) do
    Client.stream(client, @path, params)
  end

  @doc """
  Retrieves a single offer by ID.

  ## Options

    * `:params` - query string parameters, e.g.
      `params: [return_available_services: true]`

  """
  @spec get(Client.t(), String.t(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def get(client, id, opts \\ []) when is_binary(id) do
    Client.get_data(client, "#{@path}/#{id}", opts)
  end

  @doc """
  Re-prices the offer with the airline and returns the updated offer.

  ## Parameters

    * `:intended_payment_methods` - the payment methods you intend to pay
      with, e.g. `["card"]`. Prices the offer including any card fee
    * `:intended_services` - the services you intend to book alongside the
      offer, as `%{id: ..., quantity: ...}` maps

  ## Examples

      Duffel.Offers.price(client, "off_123", %{
        intended_payment_methods: ["card"],
        intended_services: [%{id: "ase_123", quantity: 1}]
      })

  """
  @spec price(Client.t(), String.t(), map(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def price(client, id, params \\ %{}, opts \\ []) when is_binary(id) do
    Client.post_data(client, "#{@path}/#{id}/actions/price", params, opts)
  end

  @doc """
  Lists the upsell offers the airline has for the same journey as `id`.

  Upsell offers cover higher fare brands and cabins for the itinerary the
  customer already picked, sorted cheapest first. Each one books like any
  other offer. Errors if the offer has expired or been booked, or if the
  airline does not support upselling.

  ## Examples

      Duffel.Offers.upsells(client, "off_123")

  """
  @spec upsells(Client.t(), String.t()) :: {:ok, [map()]} | {:error, Error.t()}
  def upsells(client, id) when is_binary(id) do
    Client.post_data(client, "#{@path}/#{id}/upsell_offers", %{})
  end

  @doc """
  Updates a passenger on an offer, e.g. to add loyalty programme accounts.

  ## Examples

      Duffel.Offers.update_passenger(client, "off_123", "pas_123", %{
        family_name: "Earhart",
        given_name: "Amelia",
        loyalty_programme_accounts: [
          %{airline_iata_code: "BA", account_number: "12901014"}
        ]
      })

  """
  @spec update_passenger(Client.t(), String.t(), String.t(), map()) ::
          {:ok, map()} | {:error, Error.t()}
  def update_passenger(client, offer_id, passenger_id, params)
      when is_binary(offer_id) and is_binary(passenger_id) do
    Client.patch_data(client, "#{@path}/#{offer_id}/passengers/#{passenger_id}", params)
  end
end
