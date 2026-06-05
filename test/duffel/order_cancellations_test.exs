defmodule Duffel.OrderCancellationsTest do
  use ExUnit.Case, async: true

  alias Duffel.{OrderCancellations, Page}

  defp client do
    Duffel.new(
      access_token: "duffel_test_abc",
      req_options: [plug: {Req.Test, __MODULE__}, retry: false]
    )
  end

  defp stub(fun), do: Req.Test.stub(__MODULE__, fun)

  describe "create/3" do
    test "creates a pending cancellation" do
      stub(fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/air/order_cancellations"

        {:ok, body, conn} = Plug.Conn.read_body(conn)
        assert %{"data" => %{"order_id" => "ord_1"}} = Jason.decode!(body)

        Req.Test.json(conn, %{
          "data" => %{"id" => "ore_1", "refund_amount" => "90.80", "confirmed_at" => nil}
        })
      end)

      assert {:ok, %{"id" => "ore_1", "refund_amount" => "90.80"}} =
               OrderCancellations.create(client(), %{order_id: "ord_1"})
    end
  end

  describe "confirm/2" do
    test "posts to the confirm action" do
      stub(fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/air/order_cancellations/ore_1/actions/confirm"

        Req.Test.json(conn, %{
          "data" => %{"id" => "ore_1", "confirmed_at" => "2026-06-04T12:00:00Z"}
        })
      end)

      assert {:ok, %{"confirmed_at" => "2026-06-04T12:00:00Z"}} =
               OrderCancellations.confirm(client(), "ore_1")
    end
  end

  describe "get/2" do
    test "fetches a single cancellation" do
      stub(fn conn ->
        assert conn.request_path == "/air/order_cancellations/ore_1"
        Req.Test.json(conn, %{"data" => %{"id" => "ore_1"}})
      end)

      assert {:ok, %{"id" => "ore_1"}} = OrderCancellations.get(client(), "ore_1")
    end
  end

  describe "list/2" do
    test "lists cancellations filtered by order" do
      stub(fn conn ->
        assert conn.query_params["order_id"] == "ord_1"

        Req.Test.json(conn, %{
          "data" => [%{"id" => "ore_1"}],
          "meta" => %{"after" => nil, "limit" => 50}
        })
      end)

      assert {:ok, %Page{data: [%{"id" => "ore_1"}]}} =
               OrderCancellations.list(client(), order_id: "ord_1")
    end

    test "list/1 defaults and stream/2" do
      stub(fn conn ->
        Req.Test.json(conn, %{"data" => [%{"id" => "ore_1"}], "meta" => %{"after" => nil}})
      end)

      assert {:ok, %Page{data: [%{"id" => "ore_1"}]}} = OrderCancellations.list(client())

      assert client() |> OrderCancellations.stream() |> Enum.map(& &1["id"]) == ["ore_1"]
    end
  end
end
