defmodule Duffel.OffersTest do
  use ExUnit.Case, async: true

  alias Duffel.{Offers, Page}

  defp client do
    Duffel.new(
      access_token: "duffel_test_abc",
      req_options: [plug: {Req.Test, __MODULE__}, retry: false]
    )
  end

  defp stub(fun), do: Req.Test.stub(__MODULE__, fun)

  describe "list/2" do
    test "lists offers for an offer request" do
      stub(fn conn ->
        assert conn.request_path == "/air/offers"
        assert conn.query_params["offer_request_id"] == "orq_1"
        assert conn.query_params["sort"] == "total_amount"

        Req.Test.json(conn, %{
          "data" => [%{"id" => "off_1", "total_amount" => "45.00"}],
          "meta" => %{"after" => nil, "limit" => 50}
        })
      end)

      assert {:ok, %Page{data: [%{"id" => "off_1"}]}} =
               Offers.list(client(), offer_request_id: "orq_1", sort: "total_amount")
    end
  end

  describe "stream/2" do
    test "streams offers across pages" do
      stub(fn conn ->
        assert conn.query_params["offer_request_id"] == "orq_1"

        case conn.query_params["after"] do
          nil ->
            Req.Test.json(conn, %{
              "data" => [%{"id" => "off_1"}],
              "meta" => %{"after" => "cur_2"}
            })

          "cur_2" ->
            Req.Test.json(conn, %{
              "data" => [%{"id" => "off_2"}],
              "meta" => %{"after" => nil}
            })
        end
      end)

      assert client()
             |> Offers.stream(offer_request_id: "orq_1")
             |> Enum.map(& &1["id"]) == ["off_1", "off_2"]
    end
  end

  describe "get/3" do
    test "fetches a single offer" do
      stub(fn conn ->
        assert conn.method == "GET"
        assert conn.request_path == "/air/offers/off_1"
        Req.Test.json(conn, %{"data" => %{"id" => "off_1"}})
      end)

      assert {:ok, %{"id" => "off_1"}} = Offers.get(client(), "off_1")
    end

    test "passes return_available_services" do
      stub(fn conn ->
        assert conn.query_params["return_available_services"] == "true"
        Req.Test.json(conn, %{"data" => %{"id" => "off_1", "available_services" => []}})
      end)

      assert {:ok, _} =
               Offers.get(client(), "off_1", params: [return_available_services: true])
    end
  end

  describe "price/4" do
    test "posts to the price action" do
      stub(fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/air/offers/off_1/actions/price"

        {:ok, body, conn} = Plug.Conn.read_body(conn)
        assert %{"data" => %{}} = Jason.decode!(body)

        Req.Test.json(conn, %{"data" => %{"id" => "off_1", "total_amount" => "47.00"}})
      end)

      assert {:ok, %{"total_amount" => "47.00"}} = Offers.price(client(), "off_1")
    end

    test "sends the intended payment methods and services" do
      stub(fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)

        assert %{
                 "data" => %{
                   "intended_payment_methods" => ["card"],
                   "intended_services" => [%{"id" => "ase_1", "quantity" => 1}]
                 }
               } = Jason.decode!(body)

        Req.Test.json(conn, %{"data" => %{"id" => "off_1", "total_amount" => "49.00"}})
      end)

      assert {:ok, %{"total_amount" => "49.00"}} =
               Offers.price(client(), "off_1", %{
                 intended_payment_methods: ["card"],
                 intended_services: [%{id: "ase_1", quantity: 1}]
               })
    end
  end

  describe "upsells/2" do
    test "posts to the upsell offers action" do
      stub(fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/air/offers/off_1/upsell_offers"

        Req.Test.json(conn, %{
          "data" => [
            %{"id" => "off_2", "total_amount" => "80.00"},
            %{"id" => "off_3", "total_amount" => "95.00"}
          ]
        })
      end)

      assert {:ok, [%{"id" => "off_2"}, %{"id" => "off_3"}]} = Offers.upsells(client(), "off_1")
    end
  end

  describe "update_passenger/4" do
    test "patches the offer passenger" do
      stub(fn conn ->
        assert conn.method == "PATCH"
        assert conn.request_path == "/air/offers/off_1/passengers/pas_1"

        {:ok, body, conn} = Plug.Conn.read_body(conn)

        assert %{"data" => %{"family_name" => "Earhart", "given_name" => "Amelia"}} =
                 Jason.decode!(body)

        Req.Test.json(conn, %{"data" => %{"id" => "pas_1", "family_name" => "Earhart"}})
      end)

      assert {:ok, %{"id" => "pas_1"}} =
               Offers.update_passenger(client(), "off_1", "pas_1", %{
                 family_name: "Earhart",
                 given_name: "Amelia"
               })
    end
  end
end
