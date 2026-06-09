defmodule Duffel.CarsTest do
  use ExUnit.Case, async: true

  alias Duffel.Cars.{Bookings, Quotes, Search}

  defp client do
    Duffel.new(
      access_token: "duffel_test_abc",
      req_options: [plug: {Req.Test, __MODULE__}, retry: false]
    )
  end

  defp stub(fun), do: Req.Test.stub(__MODULE__, fun)

  describe "Search" do
    test "create/3 posts a search" do
      stub(fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/cars/search"

        {:ok, body, conn} = Plug.Conn.read_body(conn)
        assert %{"data" => %{"driver_age" => 30}} = Jason.decode!(body)

        Req.Test.json(conn, %{"data" => %{"id" => "csr_1", "rates" => []}})
      end)

      assert {:ok, %{"id" => "csr_1"}} = Search.create(client(), %{driver_age: 30})
    end
  end

  describe "Quotes" do
    test "create/3 posts a rate_id" do
      stub(fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/cars/quotes"

        {:ok, body, conn} = Plug.Conn.read_body(conn)
        assert %{"data" => %{"rate_id" => "rat_1"}} = Jason.decode!(body)

        Req.Test.json(conn, %{"data" => %{"id" => "quo_1"}})
      end)

      assert {:ok, %{"id" => "quo_1"}} = Quotes.create(client(), %{rate_id: "rat_1"})
    end
  end

  describe "Bookings" do
    test "create/3 posts from a quote with an idempotency key" do
      stub(fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/cars/bookings"
        assert Plug.Conn.get_req_header(conn, "idempotency-key") == ["car-1"]

        {:ok, body, conn} = Plug.Conn.read_body(conn)
        assert %{"data" => %{"quote_id" => "quo_1"}} = Jason.decode!(body)

        Req.Test.json(conn, %{"data" => %{"id" => "bok_1"}})
      end)

      assert {:ok, %{"id" => "bok_1"}} =
               Bookings.create(client(), %{quote_id: "quo_1"}, idempotency_key: "car-1")
    end

    test "create/2 defaults to no opts" do
      stub(fn conn ->
        assert conn.request_path == "/cars/bookings"
        Req.Test.json(conn, %{"data" => %{"id" => "bok_1"}})
      end)

      assert {:ok, %{"id" => "bok_1"}} = Bookings.create(client(), %{quote_id: "quo_1"})
    end

    test "get/2 fetches a booking" do
      stub(fn conn ->
        assert conn.request_path == "/cars/bookings/bok_1"
        Req.Test.json(conn, %{"data" => %{"id" => "bok_1"}})
      end)

      assert {:ok, %{"id" => "bok_1"}} = Bookings.get(client(), "bok_1")
    end

    test "cancel/2 posts to the cancel action" do
      stub(fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/cars/bookings/bok_1/actions/cancel"
        Req.Test.json(conn, %{"data" => %{"id" => "bok_1", "status" => "cancelled"}})
      end)

      assert {:ok, %{"status" => "cancelled"}} = Bookings.cancel(client(), "bok_1")
    end
  end
end
