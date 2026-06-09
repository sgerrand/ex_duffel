defmodule Duffel.ThreeDSecureSessions do
  @moduledoc """
  Create 3D Secure (3DS) sessions for card payments.

  A 3DS session authenticates a tokenised card against the resource being
  paid for, satisfying Strong Customer Authentication (SCA) requirements.

  See the [Duffel documentation](https://duffel.com/docs/api/v2/three-d-secure-sessions).
  """

  alias Duffel.Client

  @path "/payments/three_d_secure_sessions"

  @doc """
  Creates a 3DS session for a card payment.

  `resource_id` is the offer, order, quote or booking being paid for.

  ## Examples

      Duffel.ThreeDSecureSessions.create(client, %{
        card_id: "tcd_123",
        resource_id: "off_123",
        services: [%{id: "ase_123", quantity: 1}]
      })

  """
  @spec create(Client.t(), map(), keyword()) :: {:ok, map()} | {:error, term()}
  def create(client, params, opts \\ []) do
    with {:ok, %{"data" => data}} <- Client.post(client, @path, params, opts) do
      {:ok, data}
    end
  end
end
