defmodule Duffel.Stays.SearchTest do
  use ExUnit.Case, async: true

  alias Duffel.Stays.Search

  defp client do
    Duffel.new(
      access_token: "duffel_test_abc",
      req_options: [plug: {Req.Test, __MODULE__}, retry: false]
    )
  end

  defp stub(fun), do: Req.Test.stub(__MODULE__, fun)

  describe "create/3" do
    test "posts the search and returns results" do
      stub(fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/stays/search"

        {:ok, body, conn} = Plug.Conn.read_body(conn)
        assert %{"data" => %{"rooms" => 1}} = Jason.decode!(body)

        Req.Test.json(conn, %{
          "data" => %{"results" => [%{"id" => "ssr_1"}], "created_at" => "2026-06-09T00:00:00Z"}
        })
      end)

      assert {:ok, %{"results" => [%{"id" => "ssr_1"}]}} =
               Search.create(client(), %{rooms: 1})
    end
  end

  describe "fetch_all_rates/2" do
    test "posts to the fetch_all_rates action" do
      stub(fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/stays/search_results/ssr_1/actions/fetch_all_rates"
        Req.Test.json(conn, %{"data" => %{"id" => "ssr_1", "rooms" => []}})
      end)

      assert {:ok, %{"id" => "ssr_1"}} = Search.fetch_all_rates(client(), "ssr_1")
    end
  end
end
