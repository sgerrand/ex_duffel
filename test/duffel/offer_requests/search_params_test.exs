defmodule Duffel.OfferRequests.SearchParamsTest do
  use ExUnit.Case, async: true

  alias Duffel.OfferRequests.SearchParams

  describe "new/1" do
    test "builds params with all optional fields" do
      params =
        SearchParams.new(
          slices: [SearchParams.slice("LHR", "JFK", "2026-07-01")],
          passengers: [SearchParams.passenger(type: "adult")],
          cabin_class: "economy",
          max_connections: 0,
          private_fares: %{"BA" => [%{corporate_code: "ABC"}]},
          airline_credit_ids: ["cre_1"]
        )

      assert params == %{
               slices: [%{origin: "LHR", destination: "JFK", departure_date: "2026-07-01"}],
               passengers: [%{type: "adult"}],
               cabin_class: "economy",
               max_connections: 0,
               private_fares: %{"BA" => [%{corporate_code: "ABC"}]},
               airline_credit_ids: ["cre_1"]
             }
    end

    test "omits optional fields when not given" do
      params =
        SearchParams.new(
          slices: [SearchParams.slice("LHR", "JFK", "2026-07-01")],
          passengers: [SearchParams.passenger(type: "adult")]
        )

      assert Map.keys(params) |> Enum.sort() == [:passengers, :slices]
    end

    test "raises when a required option is missing" do
      assert_raise ArgumentError, ~r/passengers/, fn ->
        SearchParams.new(slices: [])
      end
    end
  end

  describe "slice/4" do
    test "restricts departure and arrival times when given" do
      assert SearchParams.slice("LHR", "JFK", "2026-07-01",
               departure_time: %{from: "09:00", to: "12:00"},
               arrival_time: %{from: "12:00", to: "18:00"}
             ) == %{
               origin: "LHR",
               destination: "JFK",
               departure_date: "2026-07-01",
               departure_time: %{from: "09:00", to: "12:00"},
               arrival_time: %{from: "12:00", to: "18:00"}
             }
    end

    test "omits time ranges by default" do
      assert SearchParams.slice("LHR", "JFK", "2026-07-01") == %{
               origin: "LHR",
               destination: "JFK",
               departure_date: "2026-07-01"
             }
    end
  end

  describe "passenger/1" do
    test "keeps given fields and omits the rest" do
      assert SearchParams.passenger(type: "child", age: 9, given_name: "Sam") == %{
               type: "child",
               age: 9,
               given_name: "Sam"
             }
    end

    test "defaults to an empty map" do
      assert SearchParams.passenger() == %{}
    end
  end
end
