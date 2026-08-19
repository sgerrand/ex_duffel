defmodule Duffel.Schema.StaysTest do
  use ExUnit.Case, async: true

  alias Duffel.Schema.Stays.{
    Accommodation,
    Booking,
    Quote,
    Rate,
    Room,
    SearchResult
  }

  describe "Rate.from_map/1" do
    test "decodes scalars and keeps nested resources as raw maps" do
      rate =
        Rate.from_map(%{
          "id" => "rat_1",
          "total_amount" => "250.00",
          "total_currency" => "GBP",
          "base_amount" => "200.00",
          "base_currency" => "GBP",
          "tax_amount" => "40.00",
          "tax_currency" => "GBP",
          "fee_amount" => "10.00",
          "fee_currency" => "GBP",
          "due_at_accommodation_amount" => "15.00",
          "due_at_accommodation_currency" => "GBP",
          "public_amount" => "275.00",
          "public_currency" => "GBP",
          "board_type" => "breakfast",
          "payment_type" => "pay_now",
          "negotiated_rate_code" => "CORP1",
          "source" => "duffel",
          "supplier" => "expedia",
          "quantity_available" => 3,
          "loyalty_programme" => %{"name" => "Marriott Bonvoy"},
          "available_payment_methods" => ["balance", "card"],
          "cancellation_timeline" => [%{"refund_amount" => "250.00"}],
          "conditions" => [%{"title" => "No pets"}]
        })

      assert %Rate{
               id: "rat_1",
               total_amount: "250.00",
               total_currency: "GBP",
               base_amount: "200.00",
               base_currency: "GBP",
               tax_amount: "40.00",
               tax_currency: "GBP",
               fee_amount: "10.00",
               fee_currency: "GBP",
               due_at_accommodation_amount: "15.00",
               due_at_accommodation_currency: "GBP",
               public_amount: "275.00",
               public_currency: "GBP",
               board_type: "breakfast",
               payment_type: "pay_now",
               negotiated_rate_code: "CORP1",
               source: "duffel",
               supplier: "expedia",
               quantity_available: 3,
               loyalty_programme: %{"name" => "Marriott Bonvoy"},
               available_payment_methods: ["balance", "card"],
               cancellation_timeline: [%{"refund_amount" => "250.00"}],
               conditions: [%{"title" => "No pets"}]
             } = rate
    end

    test "defaults missing lists to []" do
      assert %Rate{
               available_payment_methods: [],
               cancellation_timeline: [],
               conditions: []
             } = Rate.from_map(%{"id" => "rat_1"})
    end
  end

  describe "Room.from_map/1" do
    test "decodes rates into structs and keeps photos/beds as raw maps" do
      room =
        Room.from_map(%{
          "name" => "Double Room",
          "photos" => [%{"url" => "https://example.com/room.jpg"}],
          "beds" => [%{"type" => "double", "count" => 1}],
          "rates" => [%{"id" => "rat_1"}, %{"id" => "rat_2"}]
        })

      assert %Room{
               name: "Double Room",
               photos: [%{"url" => "https://example.com/room.jpg"}],
               beds: [%{"type" => "double", "count" => 1}],
               rates: [%Rate{id: "rat_1"}, %Rate{id: "rat_2"}]
             } = room
    end

    test "defaults missing lists to []" do
      assert %Room{photos: [], beds: [], rates: []} = Room.from_map(%{"name" => "Double Room"})
    end
  end

  describe "Accommodation.from_map/1" do
    test "decodes rooms into structs and keeps location/brand/chain as raw maps" do
      accommodation =
        Accommodation.from_map(%{
          "id" => "acc_1",
          "name" => "The Ritz",
          "description" => "A hotel in London",
          "rating" => 5,
          "review_score" => 9.4,
          "email" => "stay@ritz.example",
          "phone_number" => "+442073002222",
          "check_in_information" => %{"check_in_after_time" => "15:00"},
          "location" => %{"address" => %{"city_name" => "London"}},
          "brand" => %{"name" => "Ritz"},
          "chain" => %{"name" => "Ritz-Carlton"},
          "key_collection" => %{"instructions" => "Front desk"},
          "supported_loyalty_programme" => "marriott_bonvoy",
          "photos" => [%{"url" => "https://example.com/hotel.jpg"}],
          "amenities" => [%{"type" => "wifi"}],
          "rooms" => [%{"name" => "Double Room", "rates" => [%{"id" => "rat_1"}]}]
        })

      assert %Accommodation{
               id: "acc_1",
               name: "The Ritz",
               description: "A hotel in London",
               rating: 5,
               review_score: 9.4,
               email: "stay@ritz.example",
               phone_number: "+442073002222",
               check_in_information: %{"check_in_after_time" => "15:00"},
               location: %{"address" => %{"city_name" => "London"}},
               brand: %{"name" => "Ritz"},
               chain: %{"name" => "Ritz-Carlton"},
               key_collection: %{"instructions" => "Front desk"},
               supported_loyalty_programme: "marriott_bonvoy",
               photos: [%{"url" => "https://example.com/hotel.jpg"}],
               amenities: [%{"type" => "wifi"}]
             } = accommodation

      assert [%Room{name: "Double Room", rates: [%Rate{id: "rat_1"}]}] = accommodation.rooms
    end

    test "defaults missing lists to []" do
      assert %Accommodation{photos: [], amenities: [], rooms: []} =
               Accommodation.from_map(%{"id" => "acc_1"})
    end
  end

  describe "SearchResult.from_map/1" do
    test "decodes the nested accommodation into a struct" do
      result =
        SearchResult.from_map(%{
          "id" => "sr_1",
          "check_in_date" => "2026-08-01",
          "check_out_date" => "2026-08-03",
          "rooms" => 1,
          "cheapest_rate_total_amount" => "250.00",
          "cheapest_rate_currency" => "GBP",
          "cheapest_rate_public_amount" => "275.00",
          "guests" => [%{"type" => "adult"}],
          "accommodation" => %{"id" => "acc_1", "rooms" => [%{"name" => "Double Room"}]}
        })

      assert %SearchResult{
               id: "sr_1",
               check_in_date: "2026-08-01",
               check_out_date: "2026-08-03",
               rooms: 1,
               cheapest_rate_total_amount: "250.00",
               cheapest_rate_currency: "GBP",
               cheapest_rate_public_amount: "275.00",
               guests: [%{"type" => "adult"}]
             } = result

      assert %Accommodation{id: "acc_1", rooms: [%Room{name: "Double Room"}]} =
               result.accommodation
    end

    test "leaves a missing accommodation as nil and defaults guests to []" do
      assert %SearchResult{accommodation: nil, guests: []} =
               SearchResult.from_map(%{"id" => "sr_1"})
    end
  end

  describe "Quote.from_map/1" do
    test "decodes the nested accommodation and rate into structs" do
      stay_quote =
        Quote.from_map(%{
          "id" => "quo_1",
          "live_mode" => false,
          "check_in_date" => "2026-08-01",
          "check_out_date" => "2026-08-03",
          "rooms" => 1,
          "total_amount" => "250.00",
          "total_currency" => "GBP",
          "base_amount" => "200.00",
          "base_currency" => "GBP",
          "tax_amount" => "40.00",
          "tax_currency" => "GBP",
          "fee_amount" => "10.00",
          "fee_currency" => "GBP",
          "due_at_accommodation_amount" => "15.00",
          "due_at_accommodation_currency" => "GBP",
          "supported_loyalty_programme" => "marriott_bonvoy",
          "guests" => [%{"type" => "adult"}],
          "accommodation" => %{"id" => "acc_1"},
          "rate" => %{"id" => "rat_1"}
        })

      assert %Quote{
               id: "quo_1",
               live_mode: false,
               check_in_date: "2026-08-01",
               check_out_date: "2026-08-03",
               rooms: 1,
               total_amount: "250.00",
               total_currency: "GBP",
               base_amount: "200.00",
               base_currency: "GBP",
               tax_amount: "40.00",
               tax_currency: "GBP",
               fee_amount: "10.00",
               fee_currency: "GBP",
               due_at_accommodation_amount: "15.00",
               due_at_accommodation_currency: "GBP",
               supported_loyalty_programme: "marriott_bonvoy",
               guests: [%{"type" => "adult"}],
               accommodation: %Accommodation{id: "acc_1"},
               rate: %Rate{id: "rat_1"}
             } = stay_quote
    end

    test "leaves missing nested resources as nil and defaults guests to []" do
      assert %Quote{accommodation: nil, rate: nil, guests: []} =
               Quote.from_map(%{"id" => "quo_1"})
    end
  end

  describe "Booking.from_map/1" do
    test "decodes the nested accommodation and keeps guests as raw maps" do
      booking =
        Booking.from_map(%{
          "id" => "bok_1",
          "live_mode" => false,
          "reference" => "ABC123",
          "status" => "confirmed",
          "confirmed_at" => "2026-07-01T00:00:00Z",
          "cancelled_at" => nil,
          "check_in_date" => "2026-08-01",
          "check_out_date" => "2026-08-03",
          "rooms" => 1,
          "email" => "amelia@duffel.com",
          "phone_number" => "+442080160508",
          "accommodation_special_requests" => "High floor",
          "loyalty_programme_account_number" => "123456",
          "key_collection" => %{"instructions" => "Front desk"},
          "payment_status" => "paid",
          "metadata" => %{"trip" => "summer"},
          "guests" => [%{"given_name" => "Amelia", "family_name" => "Earhart"}],
          "users" => ["icu_1"],
          "accommodation" => %{"id" => "acc_1", "name" => "The Ritz"}
        })

      assert %Booking{
               id: "bok_1",
               live_mode: false,
               reference: "ABC123",
               status: "confirmed",
               confirmed_at: "2026-07-01T00:00:00Z",
               cancelled_at: nil,
               check_in_date: "2026-08-01",
               check_out_date: "2026-08-03",
               rooms: 1,
               email: "amelia@duffel.com",
               phone_number: "+442080160508",
               accommodation_special_requests: "High floor",
               loyalty_programme_account_number: "123456",
               key_collection: %{"instructions" => "Front desk"},
               payment_status: "paid",
               metadata: %{"trip" => "summer"},
               guests: [%{"given_name" => "Amelia", "family_name" => "Earhart"}],
               users: ["icu_1"],
               accommodation: %Accommodation{id: "acc_1", name: "The Ritz"}
             } = booking
    end

    test "leaves a missing accommodation as nil and defaults lists to []" do
      assert %Booking{accommodation: nil, guests: [], users: []} =
               Booking.from_map(%{"id" => "bok_1"})
    end
  end
end
