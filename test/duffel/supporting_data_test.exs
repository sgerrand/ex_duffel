defmodule Duffel.SupportingDataTest do
  use ExUnit.Case, async: true

  alias Duffel.{Aircraft, Airlines, Airports, Cities, LoyaltyProgrammes, Page, Places}

  defp client do
    Duffel.new(
      access_token: "duffel_test_abc",
      req_options: [plug: {Req.Test, __MODULE__}, retry: false]
    )
  end

  defp stub(fun), do: Req.Test.stub(__MODULE__, fun)

  describe "Airlines" do
    test "list/2 and get/2" do
      stub(fn conn ->
        case conn.request_path do
          "/air/airlines" ->
            Req.Test.json(conn, %{
              "data" => [%{"id" => "arl_1", "iata_code" => "BA"}],
              "meta" => %{"after" => nil, "limit" => 50}
            })

          "/air/airlines/arl_1" ->
            Req.Test.json(conn, %{"data" => %{"id" => "arl_1", "iata_code" => "BA"}})
        end
      end)

      assert {:ok, %Page{data: [%{"iata_code" => "BA"}]}} = Airlines.list(client())
      assert {:ok, %{"iata_code" => "BA"}} = Airlines.get(client(), "arl_1")
    end

    test "stream/2 follows cursors" do
      stub(fn conn ->
        case conn.query_params["after"] do
          nil ->
            Req.Test.json(conn, %{"data" => [%{"id" => "arl_1"}], "meta" => %{"after" => "c2"}})

          "c2" ->
            Req.Test.json(conn, %{"data" => [%{"id" => "arl_2"}], "meta" => %{"after" => nil}})
        end
      end)

      assert client() |> Airlines.stream() |> Enum.map(& &1["id"]) == ["arl_1", "arl_2"]
    end
  end

  describe "Airports" do
    test "list/2 with country filter and get/2" do
      stub(fn conn ->
        case conn.request_path do
          "/air/airports" ->
            assert conn.query_params["iata_country_code"] == "GB"

            Req.Test.json(conn, %{
              "data" => [%{"id" => "arp_1", "iata_code" => "LHR"}],
              "meta" => %{"after" => nil, "limit" => 50}
            })

          "/air/airports/arp_1" ->
            Req.Test.json(conn, %{"data" => %{"id" => "arp_1", "iata_code" => "LHR"}})
        end
      end)

      assert {:ok, %Page{data: [%{"iata_code" => "LHR"}]}} =
               Airports.list(client(), iata_country_code: "GB")

      assert {:ok, %{"iata_code" => "LHR"}} = Airports.get(client(), "arp_1")
    end

    test "list/1 defaults and stream/2" do
      stub(fn conn ->
        Req.Test.json(conn, %{"data" => [%{"id" => "arp_1"}], "meta" => %{"after" => nil}})
      end)

      assert {:ok, %Page{data: [%{"id" => "arp_1"}]}} = Airports.list(client())
      assert client() |> Airports.stream() |> Enum.map(& &1["id"]) == ["arp_1"]
    end
  end

  describe "Aircraft" do
    test "list/2 and get/2" do
      stub(fn conn ->
        case conn.request_path do
          "/air/aircraft" ->
            Req.Test.json(conn, %{
              "data" => [%{"id" => "arc_1", "name" => "Airbus A350-1000"}],
              "meta" => %{"after" => nil, "limit" => 50}
            })

          "/air/aircraft/arc_1" ->
            Req.Test.json(conn, %{"data" => %{"id" => "arc_1"}})
        end
      end)

      assert {:ok, %Page{data: [%{"id" => "arc_1"}]}} = Aircraft.list(client())
      assert {:ok, %{"id" => "arc_1"}} = Aircraft.get(client(), "arc_1")
    end

    test "stream/2 follows cursors" do
      stub(fn conn ->
        Req.Test.json(conn, %{"data" => [%{"id" => "arc_1"}], "meta" => %{"after" => nil}})
      end)

      assert client() |> Aircraft.stream() |> Enum.map(& &1["id"]) == ["arc_1"]
    end
  end

  describe "Cities" do
    test "list/1, stream/2 and get/2" do
      stub(fn conn ->
        case conn.request_path do
          "/air/cities" ->
            Req.Test.json(conn, %{
              "data" => [%{"id" => "cit_1", "iata_code" => "LON"}],
              "meta" => %{"after" => nil, "limit" => 50}
            })

          "/air/cities/cit_1" ->
            Req.Test.json(conn, %{"data" => %{"id" => "cit_1"}})
        end
      end)

      assert {:ok, %Page{data: [%{"iata_code" => "LON"}]}} = Cities.list(client())
      assert client() |> Cities.stream() |> Enum.map(& &1["id"]) == ["cit_1"]
      assert {:ok, %{"id" => "cit_1"}} = Cities.get(client(), "cit_1")
    end
  end

  describe "LoyaltyProgrammes" do
    test "list/1, stream/2 and get/2" do
      stub(fn conn ->
        case conn.request_path do
          "/air/loyalty_programmes" ->
            Req.Test.json(conn, %{
              "data" => [%{"id" => "loy_1", "name" => "Executive Club"}],
              "meta" => %{"after" => nil, "limit" => 50}
            })

          "/air/loyalty_programmes/loy_1" ->
            Req.Test.json(conn, %{"data" => %{"id" => "loy_1"}})
        end
      end)

      assert {:ok, %Page{data: [%{"id" => "loy_1"}]}} = LoyaltyProgrammes.list(client())
      assert client() |> LoyaltyProgrammes.stream() |> Enum.map(& &1["id"]) == ["loy_1"]
      assert {:ok, %{"id" => "loy_1"}} = LoyaltyProgrammes.get(client(), "loy_1")
    end
  end

  describe "Places" do
    test "suggestions/2 searches by query" do
      stub(fn conn ->
        assert conn.request_path == "/places/suggestions"
        assert conn.query_params["query"] == "lond"

        Req.Test.json(conn, %{
          "data" => [%{"id" => "cit_1", "name" => "London", "type" => "city"}]
        })
      end)

      assert {:ok, [%{"name" => "London"}]} = Places.suggestions(client(), query: "lond")
    end
  end
end
