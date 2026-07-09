defmodule Duffel.Orders.CreateParamsTest do
  use ExUnit.Case, async: true

  alias Duffel.Orders.CreateParams

  describe "new/1" do
    test "builds params with all optional fields" do
      passenger = CreateParams.passenger(id: "pas_1", given_name: "Amelia")
      payment = CreateParams.payment(type: "balance", currency: "GBP", amount: "30.20")

      params =
        CreateParams.new(
          selected_offers: ["off_1"],
          passengers: [passenger],
          type: "instant",
          payments: [payment],
          services: [CreateParams.service("ase_1", 1)],
          users: ["icu_1"],
          metadata: %{customer_id: "123"}
        )

      assert params == %{
               selected_offers: ["off_1"],
               passengers: [%{id: "pas_1", given_name: "Amelia"}],
               type: "instant",
               payments: [%{type: "balance", currency: "GBP", amount: "30.20"}],
               services: [%{id: "ase_1", quantity: 1}],
               users: ["icu_1"],
               metadata: %{customer_id: "123"}
             }
    end

    test "omits optional fields when not given" do
      params =
        CreateParams.new(
          selected_offers: ["off_1"],
          passengers: [CreateParams.passenger(id: "pas_1")]
        )

      assert Map.keys(params) |> Enum.sort() == [:passengers, :selected_offers]
    end

    test "raises when a required option is missing" do
      assert_raise ArgumentError, ~r/passengers/, fn ->
        CreateParams.new(selected_offers: ["off_1"])
      end
    end
  end

  describe "passenger/1" do
    test "keeps given fields and omits the rest" do
      assert CreateParams.passenger(id: "pas_1", title: "ms", born_on: "1987-07-24") == %{
               id: "pas_1",
               title: "ms",
               born_on: "1987-07-24"
             }
    end
  end

  describe "payment/1" do
    test "keeps given fields and omits the rest" do
      assert CreateParams.payment(type: "card", card_id: "tcd_1", amount: "30.20") == %{
               type: "card",
               card_id: "tcd_1",
               amount: "30.20"
             }
    end
  end

  describe "service/2" do
    test "builds an id/quantity map" do
      assert CreateParams.service("ase_1", 2) == %{id: "ase_1", quantity: 2}
    end
  end
end
