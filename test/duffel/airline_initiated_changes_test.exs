defmodule Duffel.AirlineInitiatedChangesTest do
  use ExUnit.Case, async: true

  alias Duffel.{AirlineInitiatedChanges, Page}

  defp client do
    Duffel.new(
      access_token: "duffel_test_abc",
      req_options: [plug: {Req.Test, __MODULE__}, retry: false]
    )
  end

  defp stub(fun), do: Req.Test.stub(__MODULE__, fun)

  test "list/2 filters by order" do
    stub(fn conn ->
      assert conn.request_path == "/air/airline_initiated_changes"
      assert conn.query_params["order_id"] == "ord_1"

      Req.Test.json(conn, %{
        "data" => [%{"id" => "aic_1"}],
        "meta" => %{"after" => nil, "limit" => 50}
      })
    end)

    assert {:ok, %Page{data: [%{"id" => "aic_1"}]}} =
             AirlineInitiatedChanges.list(client(), order_id: "ord_1")
  end

  test "list/1 defaults and stream/2" do
    stub(fn conn ->
      Req.Test.json(conn, %{"data" => [%{"id" => "aic_1"}], "meta" => %{"after" => nil}})
    end)

    assert {:ok, %Page{data: [%{"id" => "aic_1"}]}} = AirlineInitiatedChanges.list(client())

    assert client() |> AirlineInitiatedChanges.stream() |> Enum.map(& &1["id"]) == ["aic_1"]
  end

  test "accept/2 posts to the accept action" do
    stub(fn conn ->
      assert conn.method == "POST"
      assert conn.request_path == "/air/airline_initiated_changes/aic_1/actions/accept"
      Req.Test.json(conn, %{"data" => %{"id" => "aic_1", "action_taken" => "accepted"}})
    end)

    assert {:ok, %{"action_taken" => "accepted"}} =
             AirlineInitiatedChanges.accept(client(), "aic_1")
  end

  test "update/3 patches the action taken" do
    stub(fn conn ->
      assert conn.method == "PATCH"
      assert conn.request_path == "/air/airline_initiated_changes/aic_1"

      {:ok, body, conn} = Plug.Conn.read_body(conn)
      assert %{"data" => %{"action_taken" => "cancelled"}} = Jason.decode!(body)

      Req.Test.json(conn, %{"data" => %{"id" => "aic_1", "action_taken" => "cancelled"}})
    end)

    assert {:ok, %{"action_taken" => "cancelled"}} =
             AirlineInitiatedChanges.update(client(), "aic_1", %{action_taken: "cancelled"})
  end
end
