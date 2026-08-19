defmodule Duffel.Stays.Brands do
  @moduledoc """
  Look up accommodation brand reference data.

  See the [Duffel documentation](https://duffel.com/docs/api/v2/stays-brands).
  """

  alias Duffel.{Client, Error}

  @path "/stays/brands"

  @doc """
  Lists accommodation brands. Not paginated.
  """
  @spec list(Client.t()) :: {:ok, [map()]} | {:error, Error.t()}
  def list(client) do
    client |> Client.get(@path) |> Client.unwrap()
  end

  @doc """
  Retrieves a single brand by ID.
  """
  @spec get(Client.t(), String.t()) :: {:ok, map()} | {:error, Error.t()}
  def get(client, id) when is_binary(id) do
    client |> Client.get("#{@path}/#{id}") |> Client.unwrap()
  end
end
