defmodule Duffel.Stays.Chains do
  @moduledoc """
  Look up accommodation chain reference data.

  See the [Duffel documentation](https://duffel.com/docs/api/v2/stays-chains).
  """

  alias Duffel.{Client, Error}

  @path "/stays/chains"

  @doc """
  Lists accommodation chains. Not paginated.
  """
  @spec list(Client.t()) :: {:ok, [map()]} | {:error, Error.t()}
  def list(client) do
    client |> Client.get(@path) |> Client.unwrap()
  end

  @doc """
  Retrieves a single chain by ID.
  """
  @spec get(Client.t(), String.t()) :: {:ok, map()} | {:error, Error.t()}
  def get(client, id) when is_binary(id) do
    client |> Client.get("#{@path}/#{id}") |> Client.unwrap()
  end
end
