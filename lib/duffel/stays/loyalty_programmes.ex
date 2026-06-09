defmodule Duffel.Stays.LoyaltyProgrammes do
  @moduledoc """
  Look up accommodation loyalty programme reference data.

  See the [Duffel documentation](https://duffel.com/docs/api/v2/stays-loyalty-programmes).
  """

  alias Duffel.Client

  @path "/stays/loyalty_programmes"

  @doc """
  Lists accommodation loyalty programmes. Not paginated.
  """
  @spec list(Client.t()) :: {:ok, [map()]} | {:error, term()}
  def list(client) do
    with {:ok, %{"data" => data}} <- Client.get(client, @path) do
      {:ok, data}
    end
  end
end
