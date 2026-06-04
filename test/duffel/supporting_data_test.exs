defmodule Duffel.SupportingDataTest do
  use ExUnit.Case, async: true

  alias Duffel.{Aircraft, Airlines, Airports, Page}

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
  end
end
