defmodule Duffel.OrderChangesTest do
  use ExUnit.Case, async: true

  alias Duffel.{OrderChangeOffers, OrderChangeRequests, OrderChanges, Page}

  defp client do
    Duffel.new(
      access_token: "duffel_test_abc",
      req_options: [plug: {Req.Test, __MODULE__}, retry: false]
    )
  end

  defp stub(fun), do: Req.Test.stub(__MODULE__, fun)

  describe "OrderChangeRequests" do
    test "create/3 posts slices to add and remove" do
      stub(fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/air/order_change_requests"

        {:ok, body, conn} = Plug.Conn.read_body(conn)

        assert %{
                 "data" => %{
                   "order_id" => "ord_1",
                   "slices" => %{
                     "remove" => [%{"slice_id" => "sli_1"}],
                     "add" => [%{"origin" => "LHR"}]
                   }
                 }
               } = Jason.decode!(body)

        Req.Test.json(conn, %{"data" => %{"id" => "ocr_1"}})
      end)

      assert {:ok, %{"id" => "ocr_1"}} =
               OrderChangeRequests.create(client(), %{
                 order_id: "ord_1",
                 slices: %{
                   remove: [%{slice_id: "sli_1"}],
                   add: [%{origin: "LHR"}]
                 }
               })
    end

    test "get/2 fetches a change request" do
      stub(fn conn ->
        assert conn.request_path == "/air/order_change_requests/ocr_1"
        Req.Test.json(conn, %{"data" => %{"id" => "ocr_1"}})
      end)

      assert {:ok, %{"id" => "ocr_1"}} = OrderChangeRequests.get(client(), "ocr_1")
    end
  end

  describe "OrderChangeOffers" do
    test "list/2 requires order_change_request_id" do
      stub(fn conn ->
        assert conn.request_path == "/air/order_change_offers"
        assert conn.query_params["order_change_request_id"] == "ocr_1"

        Req.Test.json(conn, %{
          "data" => [%{"id" => "oco_1", "change_total_amount" => "125.00"}],
          "meta" => %{"after" => nil, "limit" => 50}
        })
      end)

      assert {:ok, %Page{data: [%{"id" => "oco_1"}]}} =
               OrderChangeOffers.list(client(), order_change_request_id: "ocr_1")
    end

    test "stream/2 streams change offers" do
      stub(fn conn ->
        assert conn.query_params["order_change_request_id"] == "ocr_1"
        Req.Test.json(conn, %{"data" => [%{"id" => "oco_1"}], "meta" => %{"after" => nil}})
      end)

      assert client()
             |> OrderChangeOffers.stream(order_change_request_id: "ocr_1")
             |> Enum.map(& &1["id"]) == ["oco_1"]
    end

    test "get/2 fetches a change offer" do
      stub(fn conn ->
        assert conn.request_path == "/air/order_change_offers/oco_1"
        Req.Test.json(conn, %{"data" => %{"id" => "oco_1"}})
      end)

      assert {:ok, %{"id" => "oco_1"}} = OrderChangeOffers.get(client(), "oco_1")
    end
  end

  describe "OrderChanges" do
    test "create/3 posts the selected change offer" do
      stub(fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/air/order_changes"

        {:ok, body, conn} = Plug.Conn.read_body(conn)

        assert %{"data" => %{"selected_order_change_offer" => "oco_1"}} =
                 Jason.decode!(body)

        Req.Test.json(conn, %{"data" => %{"id" => "oce_1"}})
      end)

      assert {:ok, %{"id" => "oce_1"}} =
               OrderChanges.create(client(), %{selected_order_change_offer: "oco_1"})
    end

    test "confirm/4 posts payment to the confirm action" do
      stub(fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/air/order_changes/oce_1/actions/confirm"

        {:ok, body, conn} = Plug.Conn.read_body(conn)
        assert %{"data" => %{"payment" => %{"type" => "balance"}}} = Jason.decode!(body)

        Req.Test.json(conn, %{
          "data" => %{"id" => "oce_1", "confirmed_at" => "2026-06-04T12:00:00Z"}
        })
      end)

      assert {:ok, %{"id" => "oce_1"}} =
               OrderChanges.confirm(client(), "oce_1", %{
                 payment: %{type: "balance", currency: "GBP", amount: "125.00"}
               })
    end

    test "confirm/4 defaults to an empty body" do
      stub(fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        assert %{"data" => %{}} = Jason.decode!(body)
        Req.Test.json(conn, %{"data" => %{"id" => "oce_1"}})
      end)

      assert {:ok, _} = OrderChanges.confirm(client(), "oce_1")
    end

    test "get/2 fetches an order change" do
      stub(fn conn ->
        assert conn.request_path == "/air/order_changes/oce_1"
        Req.Test.json(conn, %{"data" => %{"id" => "oce_1"}})
      end)

      assert {:ok, %{"id" => "oce_1"}} = OrderChanges.get(client(), "oce_1")
    end
  end
end
