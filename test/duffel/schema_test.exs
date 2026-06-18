defmodule Duffel.SchemaTest do
  use ExUnit.Case, async: true

  alias Duffel.Schema

  alias Duffel.Schema.{
    Offer,
    OfferRequest,
    Order,
    Passenger,
    Payment,
    Segment,
    Slice
  }

  describe "Passenger.from_map/1" do
    test "decodes offer-side and order-side fields" do
      passenger =
        Passenger.from_map(%{
          "id" => "pas_1",
          "type" => "adult",
          "age" => 34,
          "given_name" => "Amelia",
          "family_name" => "Earhart",
          "title" => "ms",
          "gender" => "f",
          "born_on" => "1987-07-24",
          "email" => "amelia@duffel.com",
          "phone_number" => "+442080160508",
          "infant_passenger_id" => "pas_2",
          "fare_type" => "contractbulk",
          "user_id" => "icu_1",
          "loyalty_programme_accounts" => [%{"airline_iata_code" => "BA"}],
          "identity_documents" => [%{"type" => "passport"}]
        })

      assert %Passenger{
               id: "pas_1",
               type: "adult",
               age: 34,
               given_name: "Amelia",
               family_name: "Earhart",
               title: "ms",
               gender: "f",
               born_on: "1987-07-24",
               email: "amelia@duffel.com",
               phone_number: "+442080160508",
               infant_passenger_id: "pas_2",
               fare_type: "contractbulk",
               user_id: "icu_1",
               loyalty_programme_accounts: [%{"airline_iata_code" => "BA"}],
               identity_documents: [%{"type" => "passport"}]
             } = passenger
    end

    test "defaults missing lists to []" do
      assert %Passenger{loyalty_programme_accounts: [], identity_documents: []} =
               Passenger.from_map(%{"id" => "pas_1"})
    end
  end

  describe "Segment.from_map/1" do
    test "decodes scalar fields and keeps nested resources as raw maps" do
      segment =
        Segment.from_map(%{
          "id" => "seg_1",
          "origin" => %{"iata_code" => "LHR"},
          "destination" => %{"iata_code" => "JFK"},
          "origin_terminal" => "5",
          "destination_terminal" => "7",
          "departing_at" => "2026-07-01T09:00:00",
          "arriving_at" => "2026-07-01T12:00:00",
          "duration" => "PT8H",
          "distance" => "5556.0",
          "marketing_carrier" => %{"iata_code" => "BA"},
          "marketing_carrier_flight_number" => "117",
          "operating_carrier" => %{"iata_code" => "BA"},
          "operating_carrier_flight_number" => "117",
          "aircraft" => %{"name" => "Boeing 777"},
          "stops" => [%{"id" => "sto_1"}],
          "passengers" => [%{"passenger_id" => "pas_1"}]
        })

      assert %Segment{
               id: "seg_1",
               origin: %{"iata_code" => "LHR"},
               destination: %{"iata_code" => "JFK"},
               origin_terminal: "5",
               destination_terminal: "7",
               departing_at: "2026-07-01T09:00:00",
               arriving_at: "2026-07-01T12:00:00",
               duration: "PT8H",
               distance: "5556.0",
               marketing_carrier: %{"iata_code" => "BA"},
               marketing_carrier_flight_number: "117",
               operating_carrier: %{"iata_code" => "BA"},
               operating_carrier_flight_number: "117",
               aircraft: %{"name" => "Boeing 777"},
               stops: [%{"id" => "sto_1"}],
               passengers: [%{"passenger_id" => "pas_1"}]
             } = segment
    end

    test "defaults missing lists to []" do
      assert %Segment{stops: [], passengers: []} = Segment.from_map(%{"id" => "seg_1"})
    end
  end

  describe "Slice.from_map/1" do
    test "decodes segments into structs" do
      slice =
        Slice.from_map(%{
          "id" => "sli_1",
          "origin" => %{"iata_code" => "LHR"},
          "destination" => %{"iata_code" => "JFK"},
          "origin_type" => "airport",
          "destination_type" => "airport",
          "duration" => "PT8H",
          "fare_brand_name" => "Economy Basic",
          "conditions" => %{"change_before_departure" => nil},
          "segments" => [%{"id" => "seg_1"}, %{"id" => "seg_2"}]
        })

      assert %Slice{
               id: "sli_1",
               origin: %{"iata_code" => "LHR"},
               destination: %{"iata_code" => "JFK"},
               origin_type: "airport",
               destination_type: "airport",
               duration: "PT8H",
               fare_brand_name: "Economy Basic",
               conditions: %{"change_before_departure" => nil},
               segments: [%Segment{id: "seg_1"}, %Segment{id: "seg_2"}]
             } = slice
    end

    test "defaults missing segments to []" do
      assert %Slice{segments: []} = Slice.from_map(%{"id" => "sli_1"})
    end
  end

  describe "Payment.from_map/1" do
    test "decodes all fields" do
      assert %Payment{
               id: "pay_1",
               live_mode: false,
               created_at: "2026-06-01T00:00:00Z",
               type: "balance",
               amount: "45.00",
               currency: "GBP",
               order_id: "ord_1"
             } =
               Payment.from_map(%{
                 "id" => "pay_1",
                 "live_mode" => false,
                 "created_at" => "2026-06-01T00:00:00Z",
                 "type" => "balance",
                 "amount" => "45.00",
                 "currency" => "GBP",
                 "order_id" => "ord_1"
               })
    end
  end

  describe "Offer.from_map/1" do
    test "decodes scalars, nested slices/passengers, and raw maps" do
      offer =
        Offer.from_map(%{
          "id" => "off_1",
          "live_mode" => false,
          "created_at" => "2026-06-01T00:00:00Z",
          "updated_at" => "2026-06-01T00:05:00Z",
          "expires_at" => "2026-06-01T01:00:00Z",
          "partial" => false,
          "total_amount" => "350.00",
          "total_currency" => "GBP",
          "base_amount" => "300.00",
          "base_currency" => "GBP",
          "tax_amount" => "50.00",
          "tax_currency" => "GBP",
          "total_emissions_kg" => "500",
          "owner" => %{"iata_code" => "BA"},
          "payment_requirements" => %{"requires_instant_payment" => true},
          "conditions" => %{"refund_before_departure" => nil},
          "passenger_identity_documents_required" => true,
          "slices" => [%{"id" => "sli_1", "segments" => [%{"id" => "seg_1"}]}],
          "passengers" => [%{"id" => "pas_1", "type" => "adult"}],
          "available_services" => [%{"id" => "ase_1"}],
          "supported_passenger_identity_document_types" => ["passport"],
          "private_fares" => [%{"type" => "corporate"}]
        })

      assert %Offer{
               id: "off_1",
               live_mode: false,
               partial: false,
               total_amount: "350.00",
               total_currency: "GBP",
               total_emissions_kg: "500",
               owner: %{"iata_code" => "BA"},
               payment_requirements: %{"requires_instant_payment" => true},
               conditions: %{"refund_before_departure" => nil},
               passenger_identity_documents_required: true,
               available_services: [%{"id" => "ase_1"}],
               supported_passenger_identity_document_types: ["passport"],
               private_fares: [%{"type" => "corporate"}]
             } = offer

      assert [%Slice{id: "sli_1", segments: [%Segment{id: "seg_1"}]}] = offer.slices
      assert [%Passenger{id: "pas_1", type: "adult"}] = offer.passengers
    end

    test "defaults missing lists to []" do
      assert %Offer{
               slices: [],
               passengers: [],
               available_services: [],
               supported_passenger_identity_document_types: [],
               private_fares: []
             } = Offer.from_map(%{"id" => "off_1"})
    end
  end

  describe "Order.from_map/1" do
    test "decodes scalars, nested slices/passengers, and raw maps" do
      order =
        Order.from_map(%{
          "id" => "ord_1",
          "live_mode" => false,
          "created_at" => "2026-06-01T00:00:00Z",
          "booking_reference" => "RZPNX8",
          "type" => "instant",
          "awaiting_payment" => false,
          "payment_status" => %{"awaiting_payment" => false},
          "total_amount" => "350.00",
          "total_currency" => "GBP",
          "base_amount" => "300.00",
          "base_currency" => "GBP",
          "tax_amount" => "50.00",
          "tax_currency" => "GBP",
          "owner" => %{"iata_code" => "BA"},
          "conditions" => %{"refund_before_departure" => nil},
          "cancellation" => %{"id" => "ore_1"},
          "content" => "managed",
          "metadata" => %{"seat_preference" => "window"},
          "slices" => [%{"id" => "sli_1", "segments" => [%{"id" => "seg_1"}]}],
          "passengers" => [%{"id" => "pas_1", "given_name" => "Amelia"}],
          "services" => [%{"id" => "ser_1"}],
          "documents" => [%{"type" => "electronic_ticket"}],
          "airline_initiated_changes" => [%{"id" => "aic_1"}],
          "changes" => [%{"id" => "och_1"}],
          "users" => ["icu_1"]
        })

      assert %Order{
               id: "ord_1",
               booking_reference: "RZPNX8",
               type: "instant",
               awaiting_payment: false,
               payment_status: %{"awaiting_payment" => false},
               total_amount: "350.00",
               owner: %{"iata_code" => "BA"},
               conditions: %{"refund_before_departure" => nil},
               cancellation: %{"id" => "ore_1"},
               content: "managed",
               metadata: %{"seat_preference" => "window"},
               services: [%{"id" => "ser_1"}],
               documents: [%{"type" => "electronic_ticket"}],
               airline_initiated_changes: [%{"id" => "aic_1"}],
               changes: [%{"id" => "och_1"}],
               users: ["icu_1"]
             } = order

      assert [%Slice{id: "sli_1", segments: [%Segment{id: "seg_1"}]}] = order.slices
      assert [%Passenger{id: "pas_1", given_name: "Amelia"}] = order.passengers
    end

    test "defaults missing lists to []" do
      assert %Order{
               slices: [],
               passengers: [],
               services: [],
               documents: [],
               airline_initiated_changes: [],
               changes: [],
               users: []
             } = Order.from_map(%{"id" => "ord_1"})
    end
  end

  describe "OfferRequest.from_map/1" do
    test "decodes nested offers and passengers, keeps slices as raw maps" do
      offer_request =
        OfferRequest.from_map(%{
          "id" => "orq_1",
          "live_mode" => false,
          "created_at" => "2026-06-01T00:00:00Z",
          "cabin_class" => "economy",
          "client_key" => "key_abc",
          "slices" => [%{"origin" => %{"iata_code" => "LHR"}}],
          "passengers" => [%{"id" => "pas_1", "type" => "adult"}],
          "offers" => [%{"id" => "off_1", "slices" => [%{"id" => "sli_1"}]}]
        })

      assert %OfferRequest{
               id: "orq_1",
               live_mode: false,
               cabin_class: "economy",
               client_key: "key_abc",
               slices: [%{"origin" => %{"iata_code" => "LHR"}}]
             } = offer_request

      assert [%Passenger{id: "pas_1", type: "adult"}] = offer_request.passengers
      assert [%Offer{id: "off_1", slices: [%Slice{id: "sli_1"}]}] = offer_request.offers
    end

    test "defaults missing lists to []" do
      assert %OfferRequest{slices: [], passengers: [], offers: []} =
               OfferRequest.from_map(%{"id" => "orq_1"})
    end
  end

  describe "cast_list/2" do
    test "returns [] for nil" do
      assert Schema.cast_list(nil, Passenger) == []
    end

    test "maps each element through from_map/1" do
      assert [%Passenger{id: "pas_1"}, %Passenger{id: "pas_2"}] =
               Schema.cast_list([%{"id" => "pas_1"}, %{"id" => "pas_2"}], Passenger)
    end
  end
end
