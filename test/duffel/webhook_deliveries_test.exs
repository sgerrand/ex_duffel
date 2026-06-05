defmodule Duffel.WebhookDeliveriesTest do
  use ExUnit.Case, async: true

  alias Duffel.{Page, WebhookDeliveries}

  defp client do
    Duffel.new(
      access_token: "duffel_test_abc",
      req_options: [plug: {Req.Test, __MODULE__}, retry: false]
    )
  end

  defp stub(fun), do: Req.Test.stub(__MODULE__, fun)

  test "list/2 filters by webhook and outcome" do
    stub(fn conn ->
      assert conn.request_path == "/air/webhooks/deliveries"
      assert conn.query_params["webhook_id"] == "sev_1"
      assert conn.query_params["delivery_success"] == "false"

      Req.Test.json(conn, %{
        "data" => [%{"id" => "wdl_1"}],
        "meta" => %{"after" => nil, "limit" => 50}
      })
    end)

    assert {:ok, %Page{data: [%{"id" => "wdl_1"}]}} =
             WebhookDeliveries.list(client(), webhook_id: "sev_1", delivery_success: false)
  end

  test "list/1 defaults and stream/2" do
    stub(fn conn ->
      Req.Test.json(conn, %{"data" => [%{"id" => "wdl_1"}], "meta" => %{"after" => nil}})
    end)

    assert {:ok, %Page{data: [%{"id" => "wdl_1"}]}} = WebhookDeliveries.list(client())
    assert client() |> WebhookDeliveries.stream() |> Enum.map(& &1["id"]) == ["wdl_1"]
  end

  test "get/2 fetches a webhook delivery" do
    stub(fn conn ->
      assert conn.request_path == "/air/webhooks/deliveries/wdl_1"
      Req.Test.json(conn, %{"data" => %{"id" => "wdl_1"}})
    end)

    assert {:ok, %{"id" => "wdl_1"}} = WebhookDeliveries.get(client(), "wdl_1")
  end
end
