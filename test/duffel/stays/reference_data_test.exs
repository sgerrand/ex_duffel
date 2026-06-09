defmodule Duffel.Stays.ReferenceDataTest do
  use ExUnit.Case, async: true

  alias Duffel.Page
  alias Duffel.Stays.{Brands, Chains, LoyaltyProgrammes, NegotiatedRates}

  defp client do
    Duffel.new(
      access_token: "duffel_test_abc",
      req_options: [plug: {Req.Test, __MODULE__}, retry: false]
    )
  end

  defp stub(fun), do: Req.Test.stub(__MODULE__, fun)

  describe "LoyaltyProgrammes" do
    test "list/1 returns an unpaginated list" do
      stub(fn conn ->
        assert conn.request_path == "/stays/loyalty_programmes"
        Req.Test.json(conn, %{"data" => [%{"id" => "slp_1"}]})
      end)

      assert {:ok, [%{"id" => "slp_1"}]} = LoyaltyProgrammes.list(client())
    end
  end

  describe "Brands" do
    test "list/1 and get/2" do
      stub(fn conn ->
        case conn.request_path do
          "/stays/brands" -> Req.Test.json(conn, %{"data" => [%{"id" => "brd_1"}]})
          "/stays/brands/brd_1" -> Req.Test.json(conn, %{"data" => %{"id" => "brd_1"}})
        end
      end)

      assert {:ok, [%{"id" => "brd_1"}]} = Brands.list(client())
      assert {:ok, %{"id" => "brd_1"}} = Brands.get(client(), "brd_1")
    end
  end

  describe "Chains" do
    test "list/1 and get/2" do
      stub(fn conn ->
        case conn.request_path do
          "/stays/chains" -> Req.Test.json(conn, %{"data" => [%{"id" => "chn_1"}]})
          "/stays/chains/chn_1" -> Req.Test.json(conn, %{"data" => %{"id" => "chn_1"}})
        end
      end)

      assert {:ok, [%{"id" => "chn_1"}]} = Chains.list(client())
      assert {:ok, %{"id" => "chn_1"}} = Chains.get(client(), "chn_1")
    end
  end

  describe "NegotiatedRates" do
    test "create/3 posts a rate" do
      stub(fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/stays/negotiated_rates"
        Req.Test.json(conn, %{"data" => %{"id" => "snr_1"}})
      end)

      assert {:ok, %{"id" => "snr_1"}} = NegotiatedRates.create(client(), %{name: "Corp"})
    end

    test "get/2 fetches a rate" do
      stub(fn conn ->
        assert conn.request_path == "/stays/negotiated_rates/snr_1"
        Req.Test.json(conn, %{"data" => %{"id" => "snr_1"}})
      end)

      assert {:ok, %{"id" => "snr_1"}} = NegotiatedRates.get(client(), "snr_1")
    end

    test "list/1 defaults and stream/2" do
      stub(fn conn ->
        Req.Test.json(conn, %{"data" => [%{"id" => "snr_1"}], "meta" => %{"after" => nil}})
      end)

      assert {:ok, %Page{data: [%{"id" => "snr_1"}]}} = NegotiatedRates.list(client())
      assert client() |> NegotiatedRates.stream() |> Enum.map(& &1["id"]) == ["snr_1"]
    end

    test "update/3 patches a rate" do
      stub(fn conn ->
        assert conn.method == "PATCH"
        assert conn.request_path == "/stays/negotiated_rates/snr_1"
        Req.Test.json(conn, %{"data" => %{"id" => "snr_1"}})
      end)

      assert {:ok, %{"id" => "snr_1"}} =
               NegotiatedRates.update(client(), "snr_1", %{name: "New"})
    end

    test "delete/2 returns :ok" do
      stub(fn conn ->
        assert conn.method == "DELETE"
        assert conn.request_path == "/stays/negotiated_rates/snr_1"
        Plug.Conn.send_resp(conn, 204, "")
      end)

      assert :ok = NegotiatedRates.delete(client(), "snr_1")
    end
  end
end
