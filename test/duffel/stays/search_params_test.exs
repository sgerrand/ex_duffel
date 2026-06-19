defmodule Duffel.Stays.SearchParamsTest do
  use ExUnit.Case, async: true

  alias Duffel.Stays.SearchParams

  describe "new/1" do
    test "builds params with location and accommodation, defaulting rooms" do
      params =
        SearchParams.new(
          check_in_date: "2026-07-01",
          check_out_date: "2026-07-03",
          guests: [%{type: "adult"}],
          location: SearchParams.around(51.5074, -0.1278),
          accommodation: %{ids: ["acc_1"]}
        )

      assert params == %{
               check_in_date: "2026-07-01",
               check_out_date: "2026-07-03",
               rooms: 1,
               guests: [%{type: "adult"}],
               location: %{
                 radius: 5,
                 geographic_coordinates: %{latitude: 51.5074, longitude: -0.1278}
               },
               accommodation: %{ids: ["acc_1"]}
             }
    end

    test "omits location and accommodation when not given and honours rooms" do
      params =
        SearchParams.new(
          check_in_date: "2026-07-01",
          check_out_date: "2026-07-03",
          rooms: 2,
          guests: [%{type: "adult"}, %{type: "child", age: 9}]
        )

      assert params == %{
               check_in_date: "2026-07-01",
               check_out_date: "2026-07-03",
               rooms: 2,
               guests: [%{type: "adult"}, %{type: "child", age: 9}]
             }

      refute Map.has_key?(params, :location)
      refute Map.has_key?(params, :accommodation)
    end

    test "raises when a required option is missing" do
      assert_raise ArgumentError, ~r/check_out_date.*guests/, fn ->
        SearchParams.new(check_in_date: "2026-07-01")
      end
    end
  end

  describe "around/3" do
    test "defaults the radius to 5 kilometres" do
      assert SearchParams.around(51.5074, -0.1278) == %{
               radius: 5,
               geographic_coordinates: %{latitude: 51.5074, longitude: -0.1278}
             }
    end

    test "accepts an explicit radius" do
      assert SearchParams.around(40.7128, -74.0060, 10) == %{
               radius: 10,
               geographic_coordinates: %{latitude: 40.7128, longitude: -74.0060}
             }
    end
  end
end
