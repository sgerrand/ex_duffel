defmodule Duffel.WebhooksTest do
  use ExUnit.Case, async: true

  alias Duffel.{Page, Webhooks}

  defp client do
    Duffel.new(
      access_token: "duffel_test_abc",
      req_options: [plug: {Req.Test, __MODULE__}, retry: false]
    )
  end

  defp stub(fun), do: Req.Test.stub(__MODULE__, fun)

  describe "CRUD" do
    test "create/3 posts url and events" do
      stub(fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/air/webhooks"

        {:ok, body, conn} = Plug.Conn.read_body(conn)

        assert %{
                 "data" => %{
                   "url" => "https://example.com/hook",
                   "events" => ["order.created"]
                 }
               } = Jason.decode!(body)

        Req.Test.json(conn, %{"data" => %{"id" => "sev_1", "secret" => "shh"}})
      end)

      assert {:ok, %{"id" => "sev_1", "secret" => "shh"}} =
               Webhooks.create(client(), %{
                 url: "https://example.com/hook",
                 events: ["order.created"]
               })
    end

    test "get/2 fetches a webhook" do
      stub(fn conn ->
        assert conn.request_path == "/air/webhooks/sev_1"
        Req.Test.json(conn, %{"data" => %{"id" => "sev_1"}})
      end)

      assert {:ok, %{"id" => "sev_1"}} = Webhooks.get(client(), "sev_1")
    end

    test "list/2 returns a page" do
      stub(fn conn ->
        Req.Test.json(conn, %{
          "data" => [%{"id" => "sev_1"}],
          "meta" => %{"after" => nil, "limit" => 50}
        })
      end)

      assert {:ok, %Page{data: [%{"id" => "sev_1"}]}} = Webhooks.list(client())
    end

    test "update/3 patches the webhook" do
      stub(fn conn ->
        assert conn.method == "PATCH"
        assert conn.request_path == "/air/webhooks/sev_1"

        {:ok, body, conn} = Plug.Conn.read_body(conn)
        assert %{"data" => %{"active" => false}} = Jason.decode!(body)

        Req.Test.json(conn, %{"data" => %{"id" => "sev_1", "active" => false}})
      end)

      assert {:ok, %{"active" => false}} =
               Webhooks.update(client(), "sev_1", %{active: false})
    end

    test "delete/2 returns :ok" do
      stub(fn conn ->
        assert conn.method == "DELETE"
        assert conn.request_path == "/air/webhooks/sev_1"
        Plug.Conn.send_resp(conn, 204, "")
      end)

      assert :ok = Webhooks.delete(client(), "sev_1")
    end

    test "ping/2 posts to the ping action" do
      stub(fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/air/webhooks/sev_1/actions/ping"
        Plug.Conn.send_resp(conn, 204, "")
      end)

      assert :ok = Webhooks.ping(client(), "sev_1")
    end
  end

  describe "verify_signature/4" do
    @secret "a_secret"
    @body ~s({"data":{"id":"ord_1"},"type":"order.created"})

    defp sign(body, timestamp, secret \\ @secret) do
      signature =
        :hmac
        |> :crypto.mac(:sha256, secret, "#{timestamp}.#{body}")
        |> Base.encode16(case: :lower)

      "t=#{timestamp},v1=#{signature}"
    end

    test "accepts a valid signature" do
      header = sign(@body, 1_700_000_000)

      assert :ok =
               Webhooks.verify_signature(header, @body, @secret, now: 1_700_000_100)
    end

    test "accepts uppercase hex signatures" do
      header = String.upcase(sign(@body, 1_700_000_000))
      header = String.replace(header, "T=", "t=") |> String.replace("V1=", "v1=")

      assert :ok =
               Webhooks.verify_signature(header, @body, @secret, now: 1_700_000_100)
    end

    test "rejects a tampered body" do
      header = sign(@body, 1_700_000_000)

      assert {:error, :invalid_signature} =
               Webhooks.verify_signature(header, @body <> "x", @secret, now: 1_700_000_100)
    end

    test "rejects the wrong secret" do
      header = sign(@body, 1_700_000_000, "other_secret")

      assert {:error, :invalid_signature} =
               Webhooks.verify_signature(header, @body, @secret, now: 1_700_000_100)
    end

    test "rejects a stale timestamp" do
      header = sign(@body, 1_700_000_000)

      assert {:error, :timestamp_out_of_tolerance} =
               Webhooks.verify_signature(header, @body, @secret, now: 1_700_000_000 + 301)
    end

    test "allows stale timestamps with tolerance: :infinity" do
      header = sign(@body, 1_700_000_000)

      assert :ok =
               Webhooks.verify_signature(header, @body, @secret,
                 now: 1_700_010_000,
                 tolerance: :infinity
               )
    end

    test "rejects malformed headers" do
      for header <- [nil, "", "nonsense", "t=abc,v1=sig", "v1=deadbeef", "t=123"] do
        assert {:error, :invalid_format} =
                 Webhooks.verify_signature(header, @body, @secret)
      end
    end

    test "accepts when any of several v1 signatures matches" do
      timestamp = 1_700_000_000
      valid = sign(@body, timestamp)
      [_t, v1] = String.split(valid, ",")
      header = "t=#{timestamp},v1=#{String.duplicate("0", 64)},#{v1}"

      assert :ok =
               Webhooks.verify_signature(header, @body, @secret, now: timestamp)
    end
  end
end
