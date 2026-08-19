defmodule Duffel.Cities do
  @moduledoc """
  Look up city reference data.

  See the [Duffel documentation](https://duffel.com/docs/api/v2/cities).
  """

  alias Duffel.{Client, Error, Page}

  @path "/air/cities"

  @doc """
  Lists one page of cities.

  ## Parameters

    * `:limit` / `:after` / `:before` - pagination (see `Duffel.Page`)

  """
  @spec list(Client.t(), keyword() | map()) :: {:ok, Page.t()} | {:error, Error.t()}
  def list(client, params \\ []) do
    Client.list(client, @path, params)
  end

  @doc """
  Lazily streams all cities across pages.

  Raises `Duffel.Error` if a page request fails.
  """
  @spec stream(Client.t(), keyword() | map()) :: Enumerable.t()
  def stream(client, params \\ []) do
    Client.stream(client, @path, params)
  end

  @doc """
  Retrieves a single city by ID.
  """
  @spec get(Client.t(), String.t()) :: {:ok, map()} | {:error, Error.t()}
  def get(client, id) when is_binary(id) do
    Client.get_data(client, "#{@path}/#{id}")
  end
end
