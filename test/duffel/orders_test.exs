defmodule Duffel.OrdersTest do
  use ExUnit.Case, async: true

  alias Duffel.{Error, Orders, Page}

  defp client do
    Duffel.new(
      access_token: "duffel_test_abc",
      req_options: [plug: {Req.Test, __MODULE__}, retry: false]
    )
  end

  defp stub(fun), do: Req.Test.stub(__MODULE__, fun)

  describe "create/3" do
    test "posts to /air/orders and unwraps data" do
      stub(fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/air/orders"

        {:ok, body, conn} = Plug.Conn.read_body(conn)
        assert %{"data" => %{"selected_offers" => ["off_1"]}} = Jason.decode!(body)

        Req.Test.json(conn, %{"data" => %{"id" => "ord_1", "booking_reference" => "RZPNX8"}})
      end)

      assert {:ok, %{"id" => "ord_1"}} =
               Orders.create(client(), %{selected_offers: ["off_1"]})
    end

    test "sends the idempotency key header" do
      stub(fn conn ->
        assert Plug.Conn.get_req_header(conn, "idempotency-key") == ["booking-1"]
        Req.Test.json(conn, %{"data" => %{"id" => "ord_1"}})
      end)

      assert {:ok, _} =
               Orders.create(client(), %{selected_offers: ["off_1"]},
                 idempotency_key: "booking-1"
               )
    end

    test "returns the API error" do
      stub(fn conn ->
        conn
        |> Plug.Conn.put_status(422)
        |> Req.Test.json(%{
          "errors" => [%{"type" => "invalid_state_error", "code" => "offer_no_longer_available"}]
        })
      end)

      assert {:error, %Error{type: :invalid_state_error, code: "offer_no_longer_available"}} =
               Orders.create(client(), %{selected_offers: ["off_1"]})
    end
  end

  describe "get/2" do
    test "fetches a single order" do
      stub(fn conn ->
        assert conn.method == "GET"
        assert conn.request_path == "/air/orders/ord_1"
        Req.Test.json(conn, %{"data" => %{"id" => "ord_1"}})
      end)

      assert {:ok, %{"id" => "ord_1"}} = Orders.get(client(), "ord_1")
    end
  end

  describe "list/2 and stream/2" do
    test "lists orders with filters" do
      stub(fn conn ->
        assert conn.query_params["awaiting_payment"] == "true"
        assert conn.query_params["sort"] == "-created_at"

        Req.Test.json(conn, %{
          "data" => [%{"id" => "ord_1"}],
          "meta" => %{"after" => nil, "limit" => 50}
        })
      end)

      assert {:ok, %Page{data: [%{"id" => "ord_1"}]}} =
               Orders.list(client(), awaiting_payment: true, sort: "-created_at")
    end

    test "list/1 defaults to no params" do
      stub(fn conn ->
        Req.Test.json(conn, %{"data" => [], "meta" => %{"after" => nil}})
      end)

      assert {:ok, %Page{data: []}} = Orders.list(client())
    end

    test "streams orders across pages" do
      stub(fn conn ->
        case conn.query_params["after"] do
          nil ->
            Req.Test.json(conn, %{"data" => [%{"id" => "ord_1"}], "meta" => %{"after" => "c2"}})

          "c2" ->
            Req.Test.json(conn, %{"data" => [%{"id" => "ord_2"}], "meta" => %{"after" => nil}})
        end
      end)

      assert client() |> Orders.stream() |> Enum.map(& &1["id"]) == ["ord_1", "ord_2"]
    end
  end

  describe "update/3" do
    test "patches order metadata" do
      stub(fn conn ->
        assert conn.method == "PATCH"
        assert conn.request_path == "/air/orders/ord_1"

        {:ok, body, conn} = Plug.Conn.read_body(conn)
        assert %{"data" => %{"metadata" => %{"customer_id" => "123"}}} = Jason.decode!(body)

        Req.Test.json(conn, %{"data" => %{"id" => "ord_1"}})
      end)

      assert {:ok, %{"id" => "ord_1"}} =
               Orders.update(client(), "ord_1", %{metadata: %{customer_id: "123"}})
    end
  end

  describe "price/2" do
    test "posts to the price action" do
      stub(fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/air/orders/ord_1/actions/price"
        Req.Test.json(conn, %{"data" => %{"id" => "ord_1", "total_amount" => "310.00"}})
      end)

      assert {:ok, %{"total_amount" => "310.00"}} = Orders.price(client(), "ord_1")
    end
  end

  describe "available_services/2" do
    test "lists available services" do
      stub(fn conn ->
        assert conn.method == "GET"
        assert conn.request_path == "/air/orders/ord_1/available_services"
        Req.Test.json(conn, %{"data" => [%{"id" => "ase_1", "type" => "baggage"}]})
      end)

      assert {:ok, [%{"id" => "ase_1"}]} = Orders.available_services(client(), "ord_1")
    end
  end

  describe "add_services/4" do
    test "posts services with payment" do
      stub(fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/air/orders/ord_1/services"

        {:ok, body, conn} = Plug.Conn.read_body(conn)

        assert %{
                 "data" => %{
                   "add_services" => [%{"id" => "ase_1", "quantity" => 1}],
                   "payment" => %{"type" => "balance"}
                 }
               } = Jason.decode!(body)

        Req.Test.json(conn, %{"data" => %{"id" => "ord_1"}})
      end)

      assert {:ok, %{"id" => "ord_1"}} =
               Orders.add_services(client(), "ord_1", %{
                 add_services: [%{id: "ase_1", quantity: 1}],
                 payment: %{type: "balance", currency: "GBP", amount: "15.00"}
               })
    end
  end
end
