defmodule Duffel.AirlineCreditsTest do
  use ExUnit.Case, async: true

  alias Duffel.{AirlineCredits, Page}

  defp client do
    Duffel.new(
      access_token: "duffel_test_abc",
      req_options: [plug: {Req.Test, __MODULE__}, retry: false]
    )
  end

  defp stub(fun), do: Req.Test.stub(__MODULE__, fun)

  test "create/3 posts an airline credit" do
    stub(fn conn ->
      assert conn.method == "POST"
      assert conn.request_path == "/air/airline_credits"

      {:ok, body, conn} = Plug.Conn.read_body(conn)
      assert %{"data" => %{"user_id" => "icu_1"}} = Jason.decode!(body)

      Req.Test.json(conn, %{"data" => %{"id" => "act_1"}})
    end)

    assert {:ok, %{"id" => "act_1"}} = AirlineCredits.create(client(), %{user_id: "icu_1"})
  end

  test "get/2 fetches an airline credit" do
    stub(fn conn ->
      assert conn.request_path == "/air/airline_credits/act_1"
      Req.Test.json(conn, %{"data" => %{"id" => "act_1"}})
    end)

    assert {:ok, %{"id" => "act_1"}} = AirlineCredits.get(client(), "act_1")
  end

  test "list/2 filters by user" do
    stub(fn conn ->
      assert conn.query_params["user_id"] == "icu_1"

      Req.Test.json(conn, %{
        "data" => [%{"id" => "act_1"}],
        "meta" => %{"after" => nil, "limit" => 50}
      })
    end)

    assert {:ok, %Page{data: [%{"id" => "act_1"}]}} =
             AirlineCredits.list(client(), user_id: "icu_1")
  end

  test "list/1 defaults and stream/2" do
    stub(fn conn ->
      Req.Test.json(conn, %{"data" => [%{"id" => "act_1"}], "meta" => %{"after" => nil}})
    end)

    assert {:ok, %Page{data: [%{"id" => "act_1"}]}} = AirlineCredits.list(client())
    assert client() |> AirlineCredits.stream() |> Enum.map(& &1["id"]) == ["act_1"]
  end
end
