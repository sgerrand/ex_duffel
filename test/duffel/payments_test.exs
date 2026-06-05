defmodule Duffel.PaymentsTest do
  use ExUnit.Case, async: true

  alias Duffel.{Page, Payments}

  defp client do
    Duffel.new(
      access_token: "duffel_test_abc",
      req_options: [plug: {Req.Test, __MODULE__}, retry: false]
    )
  end

  defp stub(fun), do: Req.Test.stub(__MODULE__, fun)

  describe "create/3" do
    test "posts a payment for an order" do
      stub(fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/air/payments"

        {:ok, body, conn} = Plug.Conn.read_body(conn)

        assert %{
                 "data" => %{
                   "order_id" => "ord_1",
                   "payment" => %{"type" => "balance", "amount" => "30.20"}
                 }
               } = Jason.decode!(body)

        Req.Test.json(conn, %{"data" => %{"id" => "pay_1"}})
      end)

      assert {:ok, %{"id" => "pay_1"}} =
               Payments.create(client(), %{
                 order_id: "ord_1",
                 payment: %{type: "balance", currency: "GBP", amount: "30.20"}
               })
    end

    test "sends the idempotency key header" do
      stub(fn conn ->
        assert Plug.Conn.get_req_header(conn, "idempotency-key") == ["pay-1"]
        Req.Test.json(conn, %{"data" => %{"id" => "pay_1"}})
      end)

      assert {:ok, _} = Payments.create(client(), %{}, idempotency_key: "pay-1")
    end
  end

  describe "get/2" do
    test "fetches a single payment" do
      stub(fn conn ->
        assert conn.request_path == "/air/payments/pay_1"
        Req.Test.json(conn, %{"data" => %{"id" => "pay_1"}})
      end)

      assert {:ok, %{"id" => "pay_1"}} = Payments.get(client(), "pay_1")
    end
  end

  describe "list/2" do
    test "lists payments for an order" do
      stub(fn conn ->
        assert conn.query_params["order_id"] == "ord_1"

        Req.Test.json(conn, %{
          "data" => [%{"id" => "pay_1"}],
          "meta" => %{"after" => nil, "limit" => 50}
        })
      end)

      assert {:ok, %Page{data: [%{"id" => "pay_1"}]}} =
               Payments.list(client(), order_id: "ord_1")
    end
  end

  describe "stream/2" do
    test "streams payments for an order" do
      stub(fn conn ->
        assert conn.query_params["order_id"] == "ord_1"
        Req.Test.json(conn, %{"data" => [%{"id" => "pay_1"}], "meta" => %{"after" => nil}})
      end)

      assert client() |> Payments.stream(order_id: "ord_1") |> Enum.map(& &1["id"]) ==
               ["pay_1"]
    end

    test "list/1 and stream/1 default to no params" do
      stub(fn conn ->
        Req.Test.json(conn, %{"data" => [%{"id" => "pay_1"}], "meta" => %{"after" => nil}})
      end)

      assert {:ok, %Page{data: [%{"id" => "pay_1"}]}} = Payments.list(client())
      assert client() |> Payments.stream() |> Enum.map(& &1["id"]) == ["pay_1"]
    end
  end
end
