defmodule Duffel.Schema.Payment do
  @moduledoc """
  A payment made against an order.
  """

  defstruct [
    :id,
    :live_mode,
    :created_at,
    :type,
    :status,
    :amount,
    :currency,
    :order_id,
    :airline_credit_id,
    :failure_reason
  ]

  @type t :: %__MODULE__{
          id: String.t() | nil,
          live_mode: boolean() | nil,
          created_at: String.t() | nil,
          type: String.t() | nil,
          status: String.t() | nil,
          amount: String.t() | nil,
          currency: String.t() | nil,
          order_id: String.t() | nil,
          airline_credit_id: String.t() | nil,
          failure_reason: String.t() | nil
        }

  @doc "Decodes a raw payment map into a `#{inspect(__MODULE__)}`."
  @spec from_map(map() | t()) :: t()
  def from_map(%__MODULE__{} = decoded), do: decoded

  def from_map(map) when is_map(map) do
    %__MODULE__{
      id: map["id"],
      live_mode: map["live_mode"],
      created_at: map["created_at"],
      type: map["type"],
      status: map["status"],
      amount: map["amount"],
      currency: map["currency"],
      order_id: map["order_id"],
      airline_credit_id: map["airline_credit_id"],
      failure_reason: map["failure_reason"]
    }
  end
end
