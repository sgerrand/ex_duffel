defmodule Duffel.BatchOfferRequestsTest do
  use ExUnit.Case, async: true

  alias Duffel.BatchOfferRequests

  defp client do
    Duffel.new(
      access_token: "duffel_test_abc",
      req_options: [plug: {Req.Test, __MODULE__}, retry: false]
    )
  end

  defp stub(fun), do: Req.Test.stub(__MODULE__, fun)

  test "create/3 posts the search" do
    stub(fn conn ->
      assert conn.method == "POST"
      assert conn.request_path == "/air/batch_offer_requests"

      {:ok, body, conn} = Plug.Conn.read_body(conn)
      assert %{"data" => %{"cabin_class" => "economy"}} = Jason.decode!(body)

      Req.Test.json(conn, %{"data" => %{"id" => "orq_1", "total_batches" => 5}})
    end)

    assert {:ok, %{"total_batches" => 5}} =
             BatchOfferRequests.create(client(), %{cabin_class: "economy"})
  end

  test "get/2 polls for the next batch" do
    stub(fn conn ->
      assert conn.method == "GET"
      assert conn.request_path == "/air/batch_offer_requests/orq_1"
      Req.Test.json(conn, %{"data" => %{"id" => "orq_1", "remaining_batches" => 2}})
    end)

    assert {:ok, %{"remaining_batches" => 2}} = BatchOfferRequests.get(client(), "orq_1")
  end
end
