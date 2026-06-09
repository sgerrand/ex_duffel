defmodule Duffel.Stays.BookingsTest do
  use ExUnit.Case, async: true

  alias Duffel.Page
  alias Duffel.Stays.{Bookings, Quotes}

  defp client do
    Duffel.new(
      access_token: "duffel_test_abc",
      req_options: [plug: {Req.Test, __MODULE__}, retry: false]
    )
  end

  defp stub(fun), do: Req.Test.stub(__MODULE__, fun)

  describe "Quotes" do
    test "create/3 posts a rate_id" do
      stub(fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/stays/quotes"

        {:ok, body, conn} = Plug.Conn.read_body(conn)
        assert %{"data" => %{"rate_id" => "rat_1"}} = Jason.decode!(body)

        Req.Test.json(conn, %{"data" => %{"id" => "quo_1"}})
      end)

      assert {:ok, %{"id" => "quo_1"}} = Quotes.create(client(), %{rate_id: "rat_1"})
    end

    test "get/2 fetches a quote" do
      stub(fn conn ->
        assert conn.request_path == "/stays/quotes/quo_1"
        Req.Test.json(conn, %{"data" => %{"id" => "quo_1"}})
      end)

      assert {:ok, %{"id" => "quo_1"}} = Quotes.get(client(), "quo_1")
    end
  end

  describe "Bookings" do
    test "create/3 posts from a quote with an idempotency key" do
      stub(fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/stays/bookings"
        assert Plug.Conn.get_req_header(conn, "idempotency-key") == ["stay-1"]

        {:ok, body, conn} = Plug.Conn.read_body(conn)
        assert %{"data" => %{"quote_id" => "quo_1"}} = Jason.decode!(body)

        Req.Test.json(conn, %{"data" => %{"id" => "bok_1"}})
      end)

      assert {:ok, %{"id" => "bok_1"}} =
               Bookings.create(client(), %{quote_id: "quo_1"}, idempotency_key: "stay-1")
    end

    test "create/2 defaults to no opts" do
      stub(fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/stays/bookings"
        Req.Test.json(conn, %{"data" => %{"id" => "bok_1"}})
      end)

      assert {:ok, %{"id" => "bok_1"}} = Bookings.create(client(), %{quote_id: "quo_1"})
    end

    test "get/2 fetches a booking" do
      stub(fn conn ->
        assert conn.request_path == "/stays/bookings/bok_1"
        Req.Test.json(conn, %{"data" => %{"id" => "bok_1"}})
      end)

      assert {:ok, %{"id" => "bok_1"}} = Bookings.get(client(), "bok_1")
    end

    test "list/1 defaults and stream/2" do
      stub(fn conn ->
        Req.Test.json(conn, %{"data" => [%{"id" => "bok_1"}], "meta" => %{"after" => nil}})
      end)

      assert {:ok, %Page{data: [%{"id" => "bok_1"}]}} = Bookings.list(client())
      assert client() |> Bookings.stream() |> Enum.map(& &1["id"]) == ["bok_1"]
    end

    test "update/3 patches metadata and users" do
      stub(fn conn ->
        assert conn.method == "PATCH"
        assert conn.request_path == "/stays/bookings/bok_1"

        {:ok, body, conn} = Plug.Conn.read_body(conn)
        assert %{"data" => %{"metadata" => %{"ref" => "abc"}}} = Jason.decode!(body)

        Req.Test.json(conn, %{"data" => %{"id" => "bok_1"}})
      end)

      assert {:ok, %{"id" => "bok_1"}} =
               Bookings.update(client(), "bok_1", %{metadata: %{ref: "abc"}})
    end

    test "cancel/2 posts to the cancel action" do
      stub(fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/stays/bookings/bok_1/actions/cancel"
        Req.Test.json(conn, %{"data" => %{"id" => "bok_1", "status" => "cancelled"}})
      end)

      assert {:ok, %{"status" => "cancelled"}} = Bookings.cancel(client(), "bok_1")
    end

    test "create_payment_instruction/3 posts a card_id" do
      stub(fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/stays/bookings/bok_1/payment_instructions"

        {:ok, body, conn} = Plug.Conn.read_body(conn)
        assert %{"data" => %{"card_id" => "tcd_1"}} = Jason.decode!(body)

        Req.Test.json(conn, %{"data" => %{"id" => "pin_1", "booking_id" => "bok_1"}})
      end)

      assert {:ok, %{"id" => "pin_1"}} =
               Bookings.create_payment_instruction(client(), "bok_1", %{card_id: "tcd_1"})
    end
  end
end
