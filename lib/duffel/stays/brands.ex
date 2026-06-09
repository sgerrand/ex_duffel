defmodule Duffel.Stays.Brands do
  @moduledoc """
  Look up accommodation brand reference data.

  See the [Duffel documentation](https://duffel.com/docs/api/v2/stays-brands).
  """

  alias Duffel.Client

  @path "/stays/brands"

  @doc """
  Lists accommodation brands. Not paginated.
  """
  @spec list(Client.t()) :: {:ok, [map()]} | {:error, term()}
  def list(client) do
    with {:ok, %{"data" => data}} <- Client.get(client, @path) do
      {:ok, data}
    end
  end

  @doc """
  Retrieves a single brand by ID.
  """
  @spec get(Client.t(), String.t()) :: {:ok, map()} | {:error, term()}
  def get(client, id) when is_binary(id) do
    with {:ok, %{"data" => data}} <- Client.get(client, "#{@path}/#{id}") do
      {:ok, data}
    end
  end
end
