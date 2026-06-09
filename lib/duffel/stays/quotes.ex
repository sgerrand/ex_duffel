defmodule Duffel.Stays.Quotes do
  @moduledoc """
  Confirm availability and the final price for a selected rate.

  A quote is required before creating a booking.

  See the [Duffel documentation](https://duffel.com/docs/api/v2/stays-quotes).
  """

  alias Duffel.Client

  @path "/stays/quotes"

  @doc """
  Creates a quote for a rate.

  ## Examples

      Duffel.Stays.Quotes.create(client, %{rate_id: "rat_123"})

  """
  @spec create(Client.t(), map(), keyword()) :: {:ok, map()} | {:error, term()}
  def create(client, params, opts \\ []) do
    with {:ok, %{"data" => data}} <- Client.post(client, @path, params, opts) do
      {:ok, data}
    end
  end

  @doc """
  Retrieves a single quote by ID.
  """
  @spec get(Client.t(), String.t()) :: {:ok, map()} | {:error, term()}
  def get(client, id) when is_binary(id) do
    with {:ok, %{"data" => data}} <- Client.get(client, "#{@path}/#{id}") do
      {:ok, data}
    end
  end
end
