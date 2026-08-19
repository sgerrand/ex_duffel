defmodule Duffel.LoyaltyProgrammes do
  @moduledoc """
  Look up airline loyalty programme reference data.

  See the [Duffel documentation](https://duffel.com/docs/api/v2/loyalty-programmes).
  """

  alias Duffel.{Client, Error, Page}

  @path "/air/loyalty_programmes"

  @doc """
  Lists one page of loyalty programmes.

  ## Parameters

    * `:limit` / `:after` / `:before` - pagination (see `Duffel.Page`)

  """
  @spec list(Client.t(), keyword() | map()) :: {:ok, Page.t()} | {:error, Error.t()}
  def list(client, params \\ []) do
    Client.list(client, @path, params)
  end

  @doc """
  Lazily streams all loyalty programmes across pages.

  Raises `Duffel.Error` if a page request fails.
  """
  @spec stream(Client.t(), keyword() | map()) :: Enumerable.t()
  def stream(client, params \\ []) do
    Client.stream(client, @path, params)
  end

  @doc """
  Retrieves a single loyalty programme by ID.
  """
  @spec get(Client.t(), String.t()) :: {:ok, map()} | {:error, Error.t()}
  def get(client, id) when is_binary(id) do
    client |> Client.get("#{@path}/#{id}") |> Client.unwrap()
  end
end
