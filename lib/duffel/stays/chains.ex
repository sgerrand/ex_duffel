defmodule Duffel.Stays.Chains do
  @moduledoc """
  Look up accommodation chain reference data.

  See the [Duffel documentation](https://duffel.com/docs/api/v2/stays-chains).
  """

  alias Duffel.Client

  @path "/stays/chains"

  @doc """
  Lists accommodation chains. Not paginated.
  """
  @spec list(Client.t()) :: {:ok, [map()]} | {:error, term()}
  def list(client) do
    with {:ok, %{"data" => data}} <- Client.get(client, @path) do
      {:ok, data}
    end
  end

  @doc """
  Retrieves a single chain by ID.
  """
  @spec get(Client.t(), String.t()) :: {:ok, map()} | {:error, term()}
  def get(client, id) when is_binary(id) do
    with {:ok, %{"data" => data}} <- Client.get(client, "#{@path}/#{id}") do
      {:ok, data}
    end
  end
end
