defmodule Duffel.Orders.CreateParams do
  @moduledoc """
  Build the request body for `Duffel.Orders.create/3`.

  `new/1` assembles the params map and checks the required fields are
  present. `passenger/1`, `payment/1` and `service/2` build the nested
  values.

      params =
        Duffel.Orders.CreateParams.new(
          selected_offers: ["off_123"],
          passengers: [
            Duffel.Orders.CreateParams.passenger(
              id: "pas_123",
              title: "ms",
              given_name: "Amelia",
              family_name: "Earhart",
              gender: "f",
              born_on: "1987-07-24",
              email: "amelia@duffel.com",
              phone_number: "+442080160508"
            )
          ],
          payments: [
            Duffel.Orders.CreateParams.payment(
              type: "balance",
              currency: "GBP",
              amount: "30.20"
            )
          ]
        )

      Duffel.Orders.create(client, params, idempotency_key: "booking-123")

  Using the builder is optional — `create/3` still accepts a plain map.
  """

  @required [:selected_offers, :passengers]

  @passenger_fields [
    :id,
    :title,
    :given_name,
    :family_name,
    :gender,
    :born_on,
    :email,
    :phone_number,
    :infant_passenger_id,
    :identity_documents,
    :loyalty_programme_accounts,
    :user_id
  ]

  @payment_fields [:type, :amount, :currency, :card_id, :three_d_secure_session_id]

  @doc """
  Builds an order params map.

  Required: `:selected_offers` (a list with one offer ID) and
  `:passengers`. Optional: `:type` (`"instant"` or `"hold"`),
  `:payments`, `:services`, `:users` and `:metadata`. Raises
  `ArgumentError` if a required option is missing.
  """
  @spec new(keyword()) :: map()
  def new(opts) when is_list(opts) do
    require_keys(opts, @required)

    %{
      selected_offers: Keyword.fetch!(opts, :selected_offers),
      passengers: Keyword.fetch!(opts, :passengers)
    }
    |> maybe_put(:type, Keyword.get(opts, :type))
    |> maybe_put(:payments, Keyword.get(opts, :payments))
    |> maybe_put(:services, Keyword.get(opts, :services))
    |> maybe_put(:users, Keyword.get(opts, :users))
    |> maybe_put(:metadata, Keyword.get(opts, :metadata))
  end

  @doc """
  Builds a passenger. The API requires `:id`, `:title`, `:given_name`,
  `:family_name`, `:gender` and `:born_on`; `:email`, `:phone_number`,
  `:infant_passenger_id`, `:identity_documents`,
  `:loyalty_programme_accounts` and `:user_id` are optional. Absent fields
  are omitted.
  """
  @spec passenger(keyword()) :: map()
  def passenger(opts) when is_list(opts), do: take(opts, @passenger_fields)

  @doc """
  Builds a payment. Accepts `:type` (`"balance"`, `"arc_bsp_cash"` or
  `"card"`), `:amount`, `:currency`, `:card_id` and
  `:three_d_secure_session_id`. Absent fields are omitted.
  """
  @spec payment(keyword()) :: map()
  def payment(opts) when is_list(opts), do: take(opts, @payment_fields)

  @doc "Builds a service to add to the order, by ID and quantity."
  @spec service(String.t(), pos_integer()) :: map()
  def service(id, quantity) when is_binary(id) and is_integer(quantity) do
    %{id: id, quantity: quantity}
  end

  defp take(opts, fields) do
    Enum.reduce(fields, %{}, fn key, acc ->
      maybe_put(acc, key, Keyword.get(opts, key))
    end)
  end

  defp require_keys(opts, keys) do
    case Enum.reject(keys, &Keyword.has_key?(opts, &1)) do
      [] -> :ok
      missing -> raise ArgumentError, "missing required options: #{inspect(missing)}"
    end
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
