defmodule Duffel.CardsTest do
  use ExUnit.Case, async: true

  alias Duffel.{Cards, ThreeDSecureSessions}

  defp client(opts \\ []) do
    Duffel.new(
      [
        access_token: "duffel_test_abc",
        req_options: [plug: {Req.Test, __MODULE__}, retry: false]
      ] ++ opts
    )
  end

  defp stub(fun), do: Req.Test.stub(__MODULE__, fun)

  describe "Cards" do
    test "create/3 tokenises against the cards host" do
      stub(fn conn ->
        assert conn.method == "POST"
        assert conn.host == "api.duffel.cards"
        assert conn.request_path == "/payments/cards"

        {:ok, body, conn} = Plug.Conn.read_body(conn)
        assert %{"data" => %{"number" => "4242424242424242"}} = Jason.decode!(body)

        Req.Test.json(conn, %{"data" => %{"id" => "tcd_1", "live_mode" => false}})
      end)

      assert {:ok, %{"id" => "tcd_1"}} =
               Cards.create(client(), %{number: "4242424242424242"})
    end

    test "create/3 honours a custom cards_base_url" do
      stub(fn conn ->
        assert conn.host == "cards.test"
        Req.Test.json(conn, %{"data" => %{"id" => "tcd_1"}})
      end)

      assert {:ok, _} =
               Cards.create(client(cards_base_url: "https://cards.test"), %{number: "4242"})
    end

    test "delete/2 deletes against the cards host" do
      stub(fn conn ->
        assert conn.method == "DELETE"
        assert conn.host == "api.duffel.cards"
        assert conn.request_path == "/payments/cards/tcd_1"
        Plug.Conn.send_resp(conn, 204, "")
      end)

      assert :ok = Cards.delete(client(), "tcd_1")
    end
  end

  describe "ThreeDSecureSessions" do
    test "create/3 posts a session on the main host" do
      stub(fn conn ->
        assert conn.method == "POST"
        assert conn.host == "api.duffel.com"
        assert conn.request_path == "/payments/three_d_secure_sessions"

        {:ok, body, conn} = Plug.Conn.read_body(conn)

        assert %{"data" => %{"card_id" => "tcd_1", "resource_id" => "off_1"}} =
                 Jason.decode!(body)

        Req.Test.json(conn, %{"data" => %{"id" => "3ds_1", "status" => "ready_for_payment"}})
      end)

      assert {:ok, %{"id" => "3ds_1"}} =
               ThreeDSecureSessions.create(client(), %{
                 card_id: "tcd_1",
                 resource_id: "off_1",
                 services: [%{id: "ase_1", quantity: 1}]
               })
    end
  end
end
