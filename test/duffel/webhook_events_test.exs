defmodule Duffel.WebhookEventsTest do
  use Duffel.Case, async: true

  alias Duffel.{Page, WebhookEvents}

  test "list/1 defaults and stream/2" do
    stub(fn conn ->
      assert conn.request_path == "/air/webhooks/events"
      Req.Test.json(conn, %{"data" => [%{"id" => "wev_1"}], "meta" => %{"after" => nil}})
    end)

    assert {:ok, %Page{data: [%{"id" => "wev_1"}]}} = WebhookEvents.list(client())
    assert client() |> WebhookEvents.stream() |> Enum.map(& &1["id"]) == ["wev_1"]
  end

  test "get/2 fetches a webhook event" do
    stub(fn conn ->
      assert conn.request_path == "/air/webhooks/events/wev_1"
      Req.Test.json(conn, %{"data" => %{"id" => "wev_1"}})
    end)

    assert {:ok, %{"id" => "wev_1"}} = WebhookEvents.get(client(), "wev_1")
  end

  test "redeliver/2 posts to the redeliver action" do
    stub(fn conn ->
      assert conn.method == "POST"
      assert conn.request_path == "/air/webhooks/events/wev_1/actions/redeliver"
      Plug.Conn.send_resp(conn, 200, "")
    end)

    assert :ok = WebhookEvents.redeliver(client(), "wev_1")
  end
end
