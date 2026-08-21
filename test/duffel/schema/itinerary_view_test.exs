defmodule Duffel.Schema.ItineraryViewTest do
  use ExUnit.Case, async: true

  alias Duffel.Schema.ItineraryView
  alias Duffel.Schema.ItineraryView.{Brand, Itinerary, Slice}

  # The shape Duffel documents in "Choosing your search response format".
  defp response do
    %{
      "id" => "orq_1",
      "references" => %{
        "airlines" => %{
          "arl_1" => %{"name" => "Duffel Airways", "iata_code" => "ZZ"}
        },
        "places" => %{
          "arp_jfk_us" => %{"iata_code" => "JFK", "type" => "airport"},
          "arp_lhr_gb" => %{"iata_code" => "LHR", "type" => "airport"}
        },
        "aircraft" => %{
          "arc_1" => %{"name" => "Airbus A380", "iata_code" => "380"}
        }
      },
      "slices" => [
        %{
          "origin" => "arp_jfk_us",
          "destination" => "arp_lhr_gb",
          "itineraries" => [
            %{
              "segments" => [
                %{"id" => "seg_1", "origin" => "arp_jfk_us", "marketing_carrier" => "arl_1"}
              ],
              "brands" => [
                %{
                  "fare_brand_name" => "Economy Basic",
                  "offers" => [
                    %{
                      "id" => "off_1",
                      "type" => "single_ticket",
                      "owner" => "arl_1",
                      "total_amount" => "470.00",
                      "total_currency" => "GBP"
                    }
                  ]
                }
              ]
            }
          ]
        }
      ]
    }
  end

  describe "from_map/1" do
    test "decodes the slice, itinerary and brand tree" do
      view = ItineraryView.from_map(response())

      assert %ItineraryView{id: "orq_1"} = view
      assert [%Slice{origin: "arp_jfk_us", destination: "arp_lhr_gb"} = slice] = view.slices
      assert [%Itinerary{} = itinerary] = slice.itineraries
      assert [%Brand{fare_brand_name: "Economy Basic"} = brand] = itinerary.brands

      assert [%{"id" => "off_1", "type" => "single_ticket"}] = brand.offers
    end

    test "keeps segments as raw maps, since they name places and carriers by ID" do
      itinerary = response() |> ItineraryView.from_map() |> first_itinerary()

      assert [%{"id" => "seg_1", "marketing_carrier" => "arl_1"}] = itinerary.segments
    end

    test "defaults missing branches" do
      assert %ItineraryView{id: "orq_1", references: %{}, slices: []} =
               ItineraryView.from_map(%{"id" => "orq_1"})

      assert %Slice{origin: nil, destination: nil, itineraries: []} = Slice.from_map(%{})
      assert %Itinerary{segments: [], brands: []} = Itinerary.from_map(%{})
      assert %Brand{fare_brand_name: nil, offers: []} = Brand.from_map(%{})
    end

    test "gives back a struct it has already decoded" do
      view = ItineraryView.from_map(response())

      assert ItineraryView.from_map(view) == view
      assert view.slices |> hd() |> Slice.from_map() == hd(view.slices)

      itinerary = first_itinerary(view)
      assert Itinerary.from_map(itinerary) == itinerary
      assert itinerary.brands |> hd() |> Brand.from_map() == hd(itinerary.brands)
    end
  end

  describe "reference lookups" do
    test "resolve the IDs used in the tree" do
      view = ItineraryView.from_map(response())
      slice = hd(view.slices)
      offer = view |> first_itinerary() |> then(&hd(hd(&1.brands).offers))

      assert ItineraryView.place(view, slice.origin) == %{
               "iata_code" => "JFK",
               "type" => "airport"
             }

      assert ItineraryView.airline(view, offer["owner"]) == %{
               "name" => "Duffel Airways",
               "iata_code" => "ZZ"
             }

      assert ItineraryView.aircraft(view, "arc_1") == %{
               "name" => "Airbus A380",
               "iata_code" => "380"
             }
    end

    test "return nil for an unknown or missing id" do
      view = ItineraryView.from_map(response())

      assert ItineraryView.place(view, "arp_nope") == nil
      assert ItineraryView.airline(view, nil) == nil
      assert ItineraryView.aircraft(view, nil) == nil
    end

    test "return nil when the response carries no references" do
      view = ItineraryView.from_map(%{"id" => "orq_1"})

      assert ItineraryView.airline(view, "arl_1") == nil
      assert ItineraryView.place(view, "arp_jfk_us") == nil
      assert ItineraryView.aircraft(view, "arc_1") == nil
    end
  end

  defp first_itinerary(%ItineraryView{} = view) do
    view.slices |> hd() |> Map.fetch!(:itineraries) |> hd()
  end
end
