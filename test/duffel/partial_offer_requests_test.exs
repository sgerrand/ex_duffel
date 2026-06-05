defmodule Duffel.PartialOfferRequestsTest do
  use ExUnit.Case, async: true

  alias Duffel.PartialOfferRequests

  defp client do
    Duffel.new(
      access_token: "duffel_test_abc",
      req_options: [plug: {Req.Test, __MODULE__}, retry: false]
    )
  end

  defp stub(fun), do: Req.Test.stub(__MODULE__, fun)

  describe "create/3" do
    test "posts the search and passes supplier_timeout through" do
      stub(fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/air/partial_offer_requests"
        assert conn.query_params["supplier_timeout"] == "10000"

        {:ok, body, conn} = Plug.Conn.read_body(conn)
        assert %{"data" => %{"cabin_class" => "economy"}} = Jason.decode!(body)

        Req.Test.json(conn, %{"data" => %{"id" => "prq_1"}})
      end)

      assert {:ok, %{"id" => "prq_1"}} =
               PartialOfferRequests.create(client(), %{cabin_class: "economy"},
                 params: [supplier_timeout: 10_000]
               )
    end

    test "defaults to no opts" do
      stub(fn conn ->
        assert conn.query_string == ""
        Req.Test.json(conn, %{"data" => %{"id" => "prq_1"}})
      end)

      assert {:ok, %{"id" => "prq_1"}} =
               PartialOfferRequests.create(client(), %{cabin_class: "economy"})
    end
  end

  describe "get/3" do
    test "fetches without selections" do
      stub(fn conn ->
        assert conn.request_path == "/air/partial_offer_requests/prq_1"
        assert conn.query_string == ""
        Req.Test.json(conn, %{"data" => %{"id" => "prq_1"}})
      end)

      assert {:ok, %{"id" => "prq_1"}} = PartialOfferRequests.get(client(), "prq_1")
    end

    test "repeats selected_partial_offer[] for each selection" do
      stub(fn conn ->
        assert conn.query_string ==
                 "selected_partial_offer%5B%5D=off_1&selected_partial_offer%5B%5D=off_2"

        Req.Test.json(conn, %{"data" => %{"id" => "prq_1"}})
      end)

      assert {:ok, _} =
               PartialOfferRequests.get(client(), "prq_1",
                 selected_partial_offers: ["off_1", "off_2"]
               )
    end
  end

  describe "fares/3" do
    test "fetches fares for the selected partial offers" do
      stub(fn conn ->
        assert conn.request_path == "/air/partial_offer_requests/prq_1/fares"

        assert conn.query_string ==
                 "selected_partial_offer%5B%5D=off_1&selected_partial_offer%5B%5D=off_2"

        Req.Test.json(conn, %{"data" => %{"id" => "prq_1", "offers" => []}})
      end)

      assert {:ok, %{"id" => "prq_1"}} =
               PartialOfferRequests.fares(client(), "prq_1", ["off_1", "off_2"])
    end
  end
end
