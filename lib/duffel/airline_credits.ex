defmodule Duffel.AirlineCredits do
  @moduledoc """
  Manage airline credits issued to customer users, e.g. from cancellations.

  See the [Duffel documentation](https://duffel.com/docs/api/v2/airline-credits).
  """

  alias Duffel.{Client, Page}

  @path "/air/airline_credits"

  @doc """
  Creates an airline credit.
  """
  @spec create(Client.t(), map(), keyword()) :: {:ok, map()} | {:error, term()}
  def create(client, params, opts \\ []) do
    with {:ok, %{"data" => data}} <- Client.post(client, @path, params, opts) do
      {:ok, data}
    end
  end

  @doc """
  Retrieves a single airline credit by ID.
  """
  @spec get(Client.t(), String.t()) :: {:ok, map()} | {:error, term()}
  def get(client, id) when is_binary(id) do
    with {:ok, %{"data" => data}} <- Client.get(client, "#{@path}/#{id}") do
      {:ok, data}
    end
  end

  @doc """
  Lists one page of airline credits.

  ## Parameters

    * `:user_id` - filter by customer user
    * `:limit` / `:after` / `:before` - pagination (see `Duffel.Page`)

  """
  @spec list(Client.t(), keyword() | map()) :: {:ok, Page.t()} | {:error, term()}
  def list(client, params \\ []) do
    Client.list(client, @path, params)
  end

  @doc """
  Lazily streams all airline credits across pages.

  Takes the same parameters as `list/2`. Raises `Duffel.Error` if a page
  request fails.
  """
  @spec stream(Client.t(), keyword() | map()) :: Enumerable.t()
  def stream(client, params \\ []) do
    Client.stream(client, @path, params)
  end
end
