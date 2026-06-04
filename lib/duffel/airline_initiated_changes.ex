defmodule Duffel.AirlineInitiatedChanges do
  @moduledoc """
  Handle changes that airlines make to existing orders (e.g. schedule
  changes), accepting them or recording the action taken.

  See the [Duffel documentation](https://duffel.com/docs/api/v2/airline-initiated-changes).
  """

  alias Duffel.{Client, Page}

  @path "/air/airline_initiated_changes"

  @doc """
  Lists one page of airline-initiated changes.

  ## Parameters

    * `:order_id` - filter by order
    * `:limit` / `:after` / `:before` - pagination (see `Duffel.Page`)

  """
  @spec list(Client.t(), keyword() | map()) :: {:ok, Page.t()} | {:error, term()}
  def list(client, params \\ []) do
    Client.list(client, @path, params)
  end

  @doc """
  Lazily streams all airline-initiated changes across pages.

  Takes the same parameters as `list/2`. Raises `Duffel.Error` if a page
  request fails.
  """
  @spec stream(Client.t(), keyword() | map()) :: Enumerable.t()
  def stream(client, params \\ []) do
    Client.stream(client, @path, params)
  end

  @doc """
  Accepts an airline-initiated change.
  """
  @spec accept(Client.t(), String.t()) :: {:ok, map()} | {:error, term()}
  def accept(client, id) when is_binary(id) do
    with {:ok, %{"data" => data}} <-
           Client.post(client, "#{@path}/#{id}/actions/accept", %{}) do
      {:ok, data}
    end
  end

  @doc """
  Records the action taken on an airline-initiated change when it can't
  be accepted through Duffel.

  ## Examples

      Duffel.AirlineInitiatedChanges.update(client, "aic_123", %{action_taken: "accepted"})

  """
  @spec update(Client.t(), String.t(), map()) :: {:ok, map()} | {:error, term()}
  def update(client, id, params) when is_binary(id) do
    with {:ok, %{"data" => data}} <- Client.patch(client, "#{@path}/#{id}", params) do
      {:ok, data}
    end
  end
end
