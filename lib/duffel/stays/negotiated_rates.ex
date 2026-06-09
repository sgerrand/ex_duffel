defmodule Duffel.Stays.NegotiatedRates do
  @moduledoc """
  Manage negotiated (private) accommodation rates.

  See the [Duffel documentation](https://duffel.com/docs/api/v2/stays-negotiated-rates).
  """

  alias Duffel.{Client, Page}

  @path "/stays/negotiated_rates"

  @doc """
  Creates a negotiated rate.
  """
  @spec create(Client.t(), map(), keyword()) :: {:ok, map()} | {:error, term()}
  def create(client, params, opts \\ []) do
    with {:ok, %{"data" => data}} <- Client.post(client, @path, params, opts) do
      {:ok, data}
    end
  end

  @doc """
  Retrieves a single negotiated rate by ID.
  """
  @spec get(Client.t(), String.t()) :: {:ok, map()} | {:error, term()}
  def get(client, id) when is_binary(id) do
    with {:ok, %{"data" => data}} <- Client.get(client, "#{@path}/#{id}") do
      {:ok, data}
    end
  end

  @doc """
  Lists one page of negotiated rates.

  ## Parameters

    * `:limit` / `:after` / `:before` - pagination (see `Duffel.Page`)

  """
  @spec list(Client.t(), keyword() | map()) :: {:ok, Page.t()} | {:error, term()}
  def list(client, params \\ []) do
    Client.list(client, @path, params)
  end

  @doc """
  Lazily streams all negotiated rates across pages.

  Raises `Duffel.Error` if a page request fails.
  """
  @spec stream(Client.t(), keyword() | map()) :: Enumerable.t()
  def stream(client, params \\ []) do
    Client.stream(client, @path, params)
  end

  @doc """
  Updates a negotiated rate.
  """
  @spec update(Client.t(), String.t(), map()) :: {:ok, map()} | {:error, term()}
  def update(client, id, params) when is_binary(id) do
    with {:ok, %{"data" => data}} <- Client.patch(client, "#{@path}/#{id}", params) do
      {:ok, data}
    end
  end

  @doc """
  Deletes a negotiated rate.
  """
  @spec delete(Client.t(), String.t()) :: :ok | {:error, term()}
  def delete(client, id) when is_binary(id) do
    with {:ok, _body} <- Client.delete(client, "#{@path}/#{id}") do
      :ok
    end
  end
end
