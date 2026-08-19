defmodule Duffel.Stays.Quotes do
  @moduledoc """
  Confirm availability and the final price for a selected rate.

  A quote is required before creating a booking.

  See the [Duffel documentation](https://duffel.com/docs/api/v2/stays-quotes).
  """

  alias Duffel.{Client, Error}

  @path "/stays/quotes"

  @doc """
  Creates a quote for a rate.

  ## Examples

      Duffel.Stays.Quotes.create(client, %{rate_id: "rat_123"})

  """
  @spec create(Client.t(), map(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def create(client, params, opts \\ []) do
    client |> Client.post(@path, params, opts) |> Client.unwrap()
  end

  @doc """
  Retrieves a single quote by ID.
  """
  @spec get(Client.t(), String.t()) :: {:ok, map()} | {:error, Error.t()}
  def get(client, id) when is_binary(id) do
    client |> Client.get("#{@path}/#{id}") |> Client.unwrap()
  end
end
