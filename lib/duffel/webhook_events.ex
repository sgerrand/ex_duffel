defmodule Duffel.WebhookEvents do
  @moduledoc """
  Inspect and redeliver events sent to your webhooks.

  See the [Duffel documentation](https://duffel.com/docs/api/v2/webhook-events).
  """

  alias Duffel.{Client, Error, Page}

  @path "/air/webhooks/events"

  @doc """
  Lists one page of webhook events.

  ## Parameters

    * `:limit` / `:after` / `:before` - pagination (see `Duffel.Page`)

  """
  @spec list(Client.t(), keyword() | map()) :: {:ok, Page.t()} | {:error, Error.t()}
  def list(client, params \\ []) do
    Client.list(client, @path, params)
  end

  @doc """
  Lazily streams all webhook events across pages.

  Raises `Duffel.Error` if a page request fails.
  """
  @spec stream(Client.t(), keyword() | map()) :: Enumerable.t()
  def stream(client, params \\ []) do
    Client.stream(client, @path, params)
  end

  @doc """
  Retrieves a single webhook event by ID.
  """
  @spec get(Client.t(), String.t()) :: {:ok, map()} | {:error, Error.t()}
  def get(client, id) when is_binary(id) do
    Client.get_data(client, "#{@path}/#{id}")
  end

  @doc """
  Queues a webhook event for redelivery.
  """
  @spec redeliver(Client.t(), String.t()) :: :ok | {:error, Error.t()}
  def redeliver(client, id) when is_binary(id) do
    client |> Client.post("#{@path}/#{id}/actions/redeliver", %{}) |> Client.discard()
  end
end
