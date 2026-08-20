defmodule Duffel.OfferRequests do
  @moduledoc """
  Search for flights by creating offer requests.

  An offer request describes the passengers and journeys (`slices`) you
  want to search for; Duffel responds with offers from airlines.

  See the [Duffel documentation](https://duffel.com/docs/api/v2/offer-requests).
  """

  alias Duffel.{Client, Error, Page}

  @path "/air/offer_requests"

  @doc """
  Creates an offer request and kicks off a flight search.

  Build the params by hand or with `Duffel.OfferRequests.SearchParams`.

  ## Options

    * `:params` - query string parameters, e.g.
      `params: [return_offers: false, supplier_timeout: 10_000]`

  ## Examples

      alias Duffel.OfferRequests.SearchParams

      params =
        SearchParams.new(
          slices: [SearchParams.slice("LHR", "JFK", "2026-07-01")],
          passengers: [SearchParams.passenger(type: "adult")],
          cabin_class: "economy"
        )

      Duffel.OfferRequests.create(client, params)

  """
  @spec create(Client.t(), map(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def create(client, params, opts \\ []) do
    Client.post_data(client, @path, params, opts)
  end

  @doc """
  Retrieves a single offer request by ID.

  ## Options

    * `:params` - query string parameters. `view: "itineraries"` groups the
      offers into slices, itineraries and brands with shared airlines,
      places and aircraft in top-level reference maps, instead of the flat
      list of offers `view: "offers"` (the default) returns

  ## Examples

      Duffel.OfferRequests.get(client, "orq_123", params: [view: "itineraries"])

  """
  @spec get(Client.t(), String.t(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def get(client, id, opts \\ []) when is_binary(id) do
    Client.get_data(client, "#{@path}/#{id}", opts)
  end

  @doc """
  Lists one page of offer requests.

  ## Parameters

    * `:limit` - results per page, 1..200 (default 50)
    * `:after` / `:before` - pagination cursors (see `Duffel.Page`)

  """
  @spec list(Client.t(), keyword() | map()) :: {:ok, Page.t()} | {:error, Error.t()}
  def list(client, params \\ []) do
    Client.list(client, @path, params)
  end

  @doc """
  Lazily streams all offer requests across pages.

  Raises `Duffel.Error` if a page request fails.

  ## Examples

      client |> Duffel.OfferRequests.stream() |> Enum.take(100)

  """
  @spec stream(Client.t(), keyword() | map()) :: Enumerable.t()
  def stream(client, params \\ []) do
    Client.stream(client, @path, params)
  end
end
