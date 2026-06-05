defmodule Duffel.WebhookDeliveries do
  @moduledoc """
  Inspect delivery attempts for your webhooks.

  See the [Duffel documentation](https://duffel.com/docs/api/v2/webhook-deliveries).
  """

  alias Duffel.{Client, Page}

  @path "/air/webhooks/deliveries"

  @doc """
  Lists one page of webhook deliveries.

  ## Parameters

    * `:webhook_id` - filter by webhook
    * `:delivery_success` - filter by delivery outcome (boolean)
    * `:limit` / `:after` / `:before` - pagination (see `Duffel.Page`)

  """
  @spec list(Client.t(), keyword() | map()) :: {:ok, Page.t()} | {:error, term()}
  def list(client, params \\ []) do
    Client.list(client, @path, params)
  end

  @doc """
  Lazily streams all webhook deliveries across pages.

  Takes the same parameters as `list/2`. Raises `Duffel.Error` if a page
  request fails.
  """
  @spec stream(Client.t(), keyword() | map()) :: Enumerable.t()
  def stream(client, params \\ []) do
    Client.stream(client, @path, params)
  end

  @doc """
  Retrieves a single webhook delivery by ID.
  """
  @spec get(Client.t(), String.t()) :: {:ok, map()} | {:error, term()}
  def get(client, id) when is_binary(id) do
    with {:ok, %{"data" => data}} <- Client.get(client, "#{@path}/#{id}") do
      {:ok, data}
    end
  end
end
