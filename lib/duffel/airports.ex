defmodule Duffel.Airports do
  @moduledoc """
  Look up airport reference data.

  See the [Duffel documentation](https://duffel.com/docs/api/v2/airports).
  """

  alias Duffel.{Client, Page}

  @path "/air/airports"

  @doc """
  Lists one page of airports.

  ## Parameters

    * `:iata_country_code` - filter by ISO 3166-1 alpha-2 country code
    * `:iata_code` - filter by IATA airport code
    * `:limit` / `:after` / `:before` - pagination (see `Duffel.Page`)

  """
  @spec list(Client.t(), keyword() | map()) :: {:ok, Page.t()} | {:error, term()}
  def list(client, params \\ []) do
    Client.list(client, @path, params)
  end

  @doc """
  Lazily streams all airports across pages.

  Takes the same parameters as `list/2`. Raises `Duffel.Error` if a page
  request fails.
  """
  @spec stream(Client.t(), keyword() | map()) :: Enumerable.t()
  def stream(client, params \\ []) do
    Client.stream(client, @path, params)
  end

  @doc """
  Retrieves a single airport by ID.
  """
  @spec get(Client.t(), String.t()) :: {:ok, map()} | {:error, term()}
  def get(client, id) when is_binary(id) do
    with {:ok, %{"data" => data}} <- Client.get(client, "#{@path}/#{id}") do
      {:ok, data}
    end
  end
end
