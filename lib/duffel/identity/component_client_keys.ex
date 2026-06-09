defmodule Duffel.Identity.ComponentClientKeys do
  @moduledoc """
  Create short-lived keys for authenticating Duffel UI components in the
  browser.

  Scope the key by passing user and/or resource IDs, so the component can
  only act on what you allow.

  See the [Duffel documentation](https://duffel.com/docs/api/v2/component-client-keys).
  """

  alias Duffel.Client

  @path "/identity/component_client_keys"

  @doc """
  Creates a component client key.

  Pass any of `:user_id`, `:order_id`, `:booking_id` or
  `:offer_request_id` in `params` to scope the key; omit `params` for an
  unscoped key.

  ## Examples

      Duffel.Identity.ComponentClientKeys.create(client, %{order_id: "ord_123"})

  """
  @spec create(Client.t(), map(), keyword()) :: {:ok, map()} | {:error, term()}
  def create(client, params \\ %{}, opts \\ []) do
    with {:ok, %{"data" => data}} <- Client.post(client, @path, params, opts) do
      {:ok, data}
    end
  end
end
