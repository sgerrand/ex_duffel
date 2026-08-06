defmodule Duffel.Schema.CarsTest do
  use ExUnit.Case, async: true

  alias Duffel.Schema.Cars.{Booking, Quote, Rate, Search}

  describe "Rate.from_map/1" do
    test "decodes scalars and keeps car/supplier/mileage as raw maps" do
      rate =
        Rate.from_map(%{
          "id" => "rat_1",
          "total_amount" => "180.00",
          "total_currency" => "GBP",
          "base_amount" => "150.00",
          "base_currency" => "GBP",
          "payment_type" => "prepaid",
          "car" => %{"name" => "Ford Focus", "category" => "compact"},
          "supplier" => %{"name" => "Hertz"},
          "mileage" => %{"unlimited" => true},
          "charges" => [%{"type" => "young_driver_fee"}],
          "conditions" => [%{"title" => "Fuel policy"}]
        })

      assert %Rate{
               id: "rat_1",
               total_amount: "180.00",
               total_currency: "GBP",
               base_amount: "150.00",
               base_currency: "GBP",
               payment_type: "prepaid",
               car: %{"name" => "Ford Focus", "category" => "compact"},
               supplier: %{"name" => "Hertz"},
               mileage: %{"unlimited" => true},
               charges: [%{"type" => "young_driver_fee"}],
               conditions: [%{"title" => "Fuel policy"}]
             } = rate
    end

    test "defaults missing lists to []" do
      assert %Rate{charges: [], conditions: []} = Rate.from_map(%{"id" => "rat_1"})
    end
  end

  describe "Search.from_map/1" do
    test "decodes rates into structs and keeps locations as raw maps" do
      search =
        Search.from_map(%{
          "id" => "sea_1",
          "live_mode" => false,
          "created_at" => "2026-07-01T00:00:00Z",
          "driver" => %{"age" => 30},
          "pickup_date" => "2026-08-01",
          "pickup_time" => "10:00",
          "pickup_location" => %{"iata_code" => "LHR"},
          "dropoff_date" => "2026-08-05",
          "dropoff_time" => "14:00",
          "dropoff_location" => %{"iata_code" => "LGW"},
          "rates" => [%{"id" => "rat_1"}, %{"id" => "rat_2"}]
        })

      assert %Search{
               id: "sea_1",
               live_mode: false,
               created_at: "2026-07-01T00:00:00Z",
               driver: %{"age" => 30},
               pickup_date: "2026-08-01",
               pickup_time: "10:00",
               pickup_location: %{"iata_code" => "LHR"},
               dropoff_date: "2026-08-05",
               dropoff_time: "14:00",
               dropoff_location: %{"iata_code" => "LGW"},
               rates: [%Rate{id: "rat_1"}, %Rate{id: "rat_2"}]
             } = search
    end

    test "defaults missing rates to []" do
      assert %Search{rates: []} = Search.from_map(%{"id" => "sea_1"})
    end
  end

  describe "Quote.from_map/1" do
    test "decodes scalars and keeps nested resources as raw maps" do
      car_quote =
        Quote.from_map(%{
          "id" => "quo_1",
          "live_mode" => false,
          "rate_id" => "rat_1",
          "search_id" => "sea_1",
          "total_amount" => "180.00",
          "total_currency" => "GBP",
          "base_amount" => "150.00",
          "base_currency" => "GBP",
          "payment_type" => "prepaid",
          "pickup_date" => "2026-08-01",
          "pickup_time" => "10:00",
          "pickup_location" => %{"iata_code" => "LHR"},
          "dropoff_date" => "2026-08-05",
          "dropoff_time" => "14:00",
          "dropoff_location" => %{"iata_code" => "LGW"},
          "car" => %{"name" => "Ford Focus"},
          "supplier" => %{"name" => "Hertz"},
          "mileage" => %{"unlimited" => true},
          "charges" => [%{"type" => "young_driver_fee"}],
          "conditions" => [%{"title" => "Fuel policy"}],
          "privacy_policies" => [%{"url" => "https://example.com/privacy"}]
        })

      assert %Quote{
               id: "quo_1",
               live_mode: false,
               rate_id: "rat_1",
               search_id: "sea_1",
               total_amount: "180.00",
               total_currency: "GBP",
               base_amount: "150.00",
               base_currency: "GBP",
               payment_type: "prepaid",
               pickup_date: "2026-08-01",
               pickup_time: "10:00",
               pickup_location: %{"iata_code" => "LHR"},
               dropoff_date: "2026-08-05",
               dropoff_time: "14:00",
               dropoff_location: %{"iata_code" => "LGW"},
               car: %{"name" => "Ford Focus"},
               supplier: %{"name" => "Hertz"},
               mileage: %{"unlimited" => true},
               charges: [%{"type" => "young_driver_fee"}],
               conditions: [%{"title" => "Fuel policy"}],
               privacy_policies: [%{"url" => "https://example.com/privacy"}]
             } = car_quote
    end

    test "defaults missing lists to []" do
      assert %Quote{charges: [], conditions: [], privacy_policies: []} =
               Quote.from_map(%{"id" => "quo_1"})
    end
  end

  describe "Booking.from_map/1" do
    test "decodes scalars and keeps driver/car/supplier as raw maps" do
      booking =
        Booking.from_map(%{
          "id" => "bok_1",
          "live_mode" => false,
          "reference" => "ABC123",
          "status" => "confirmed",
          "quote_id" => "quo_1",
          "driver" => %{"given_name" => "Amelia", "family_name" => "Earhart"},
          "car" => %{"name" => "Ford Focus"},
          "supplier" => %{"name" => "Hertz"},
          "pickup_date" => "2026-08-01",
          "pickup_time" => "10:00",
          "pickup_location" => %{"iata_code" => "LHR"},
          "dropoff_date" => "2026-08-05",
          "dropoff_time" => "14:00",
          "dropoff_location" => %{"iata_code" => "LGW"},
          "total_amount" => "180.00",
          "total_currency" => "GBP",
          "base_amount" => "150.00",
          "base_currency" => "GBP",
          "payment_type" => "prepaid",
          "mileage" => %{"unlimited" => true},
          "confirmed_at" => "2026-07-01T00:00:00Z",
          "cancelled_at" => nil,
          "metadata" => %{"trip" => "summer"},
          "charges" => [%{"type" => "young_driver_fee"}],
          "conditions" => [%{"title" => "Fuel policy"}],
          "privacy_policies" => [%{"url" => "https://example.com/privacy"}],
          "users" => ["icu_1"]
        })

      assert %Booking{
               id: "bok_1",
               live_mode: false,
               reference: "ABC123",
               status: "confirmed",
               quote_id: "quo_1",
               driver: %{"given_name" => "Amelia", "family_name" => "Earhart"},
               car: %{"name" => "Ford Focus"},
               supplier: %{"name" => "Hertz"},
               pickup_date: "2026-08-01",
               pickup_time: "10:00",
               pickup_location: %{"iata_code" => "LHR"},
               dropoff_date: "2026-08-05",
               dropoff_time: "14:00",
               dropoff_location: %{"iata_code" => "LGW"},
               total_amount: "180.00",
               total_currency: "GBP",
               base_amount: "150.00",
               base_currency: "GBP",
               payment_type: "prepaid",
               mileage: %{"unlimited" => true},
               confirmed_at: "2026-07-01T00:00:00Z",
               cancelled_at: nil,
               metadata: %{"trip" => "summer"},
               charges: [%{"type" => "young_driver_fee"}],
               conditions: [%{"title" => "Fuel policy"}],
               privacy_policies: [%{"url" => "https://example.com/privacy"}],
               users: ["icu_1"]
             } = booking
    end

    test "defaults missing lists to []" do
      assert %Booking{charges: [], conditions: [], privacy_policies: [], users: []} =
               Booking.from_map(%{"id" => "bok_1"})
    end
  end
end
