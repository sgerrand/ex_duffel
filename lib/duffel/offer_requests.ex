defmodule Duffel.OfferRequests do
  @moduledoc """
  Search for flights by creating offer requests.

  An offer request describes the passengers and journeys (`slices`) you
  want to search for; Duffel responds with offers from airlines.

  See the [Duffel documentation](https://duffel.com/docs/api/v2/offer-requests).
  """

  alias Duffel.{Client, Page}

  @path "/air/offer_requests"

  @doc """
  Creates an offer request and kicks off a flight search.

  ## Options

    * `:params` - query string parameters, e.g.
      `params: [return_offers: false, supplier_timeout: 10_000]`

  ## Examples

      Duffel.OfferRequests.create(client, %{
        slices: [
          %{origin: "LHR", destination: "JFK", departure_date: "2026-07-01"}
        ],
        passengers: [%{type: "adult"}],
        cabin_class: "economy"
      })

  """
  @spec create(Client.t(), map(), keyword()) :: {:ok, map()} | {:error, term()}
  def create(client, params, opts \\ []) do
    with {:ok, %{"data" => data}} <- Client.post(client, @path, params, opts) do
      {:ok, data}
    end
  end

  @doc """
  Retrieves a single offer request by ID.
  """
  @spec get(Client.t(), String.t()) :: {:ok, map()} | {:error, term()}
  def get(client, id) when is_binary(id) do
    with {:ok, %{"data" => data}} <- Client.get(client, "#{@path}/#{id}") do
      {:ok, data}
    end
  end

  @doc """
  Lists one page of offer requests.

  ## Parameters

    * `:limit` - results per page, 1..200 (default 50)
    * `:after` / `:before` - pagination cursors (see `Duffel.Page`)

  """
  @spec list(Client.t(), keyword() | map()) :: {:ok, Page.t()} | {:error, term()}
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
