defmodule Duffel.Cars.SearchParamsTest do
  use ExUnit.Case, async: true

  alias Duffel.Cars.SearchParams

  describe "new/1" do
    test "builds the full params map" do
      params =
        SearchParams.new(
          driver: %{age: 30},
          pickup_date: "2026-07-01",
          pickup_time: "10:00",
          pickup_location: SearchParams.at_airport("LHR"),
          dropoff_date: "2026-07-03",
          dropoff_time: "10:00",
          dropoff_location: SearchParams.at_coordinates(51.47, -0.4543)
        )

      assert params == %{
               driver: %{age: 30},
               pickup_date: "2026-07-01",
               pickup_time: "10:00",
               pickup_location: %{iata_code: "LHR"},
               dropoff_date: "2026-07-03",
               dropoff_time: "10:00",
               dropoff_location: %{
                 geographic_coordinates: %{latitude: 51.47, longitude: -0.4543}
               }
             }
    end

    test "raises when a required option is missing" do
      assert_raise ArgumentError, ~r/dropoff_location/, fn ->
        SearchParams.new(
          driver: %{age: 30},
          pickup_date: "2026-07-01",
          pickup_time: "10:00",
          pickup_location: SearchParams.at_airport("LHR"),
          dropoff_date: "2026-07-03",
          dropoff_time: "10:00"
        )
      end
    end
  end

  describe "driver/1" do
    test "keeps given fields and omits the rest" do
      assert SearchParams.driver(age: 30, email: "amelia@duffel.com") == %{
               age: 30,
               email: "amelia@duffel.com"
             }
    end

    test "defaults to an empty map" do
      assert SearchParams.driver() == %{}
    end
  end

  describe "location helpers" do
    test "at_airport/1 builds an IATA location" do
      assert SearchParams.at_airport("LHR") == %{iata_code: "LHR"}
    end

    test "at_coordinates/2 builds a coordinate location" do
      assert SearchParams.at_coordinates(51.47, -0.4543) == %{
               geographic_coordinates: %{latitude: 51.47, longitude: -0.4543}
             }
    end
  end
end
