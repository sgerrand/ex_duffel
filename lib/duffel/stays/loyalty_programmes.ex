defmodule Duffel.Stays.LoyaltyProgrammes do
  @moduledoc """
  Look up accommodation loyalty programme reference data.

  See the [Duffel documentation](https://duffel.com/docs/api/v2/stays-loyalty-programmes).
  """

  alias Duffel.{Client, Error}

  @path "/stays/loyalty_programmes"

  @doc """
  Lists accommodation loyalty programmes. Not paginated.
  """
  @spec list(Client.t()) :: {:ok, [map()]} | {:error, Error.t()}
  def list(client) do
    Client.get_data(client, @path)
  end
end
