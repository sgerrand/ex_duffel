defmodule Duffel.Stays.AccommodationTest do
  use ExUnit.Case, async: true

  alias Duffel.Page
  alias Duffel.Stays.Accommodation

  defp client do
    Duffel.new(
      access_token: "duffel_test_abc",
      req_options: [plug: {Req.Test, __MODULE__}, retry: false]
    )
  end

  defp stub(fun), do: Req.Test.stub(__MODULE__, fun)

  test "list/1 defaults and stream/2" do
    stub(fn conn ->
      assert conn.request_path == "/stays/accommodation"
      Req.Test.json(conn, %{"data" => [%{"id" => "acc_1"}], "meta" => %{"after" => nil}})
    end)

    assert {:ok, %Page{data: [%{"id" => "acc_1"}]}} = Accommodation.list(client())
    assert client() |> Accommodation.stream() |> Enum.map(& &1["id"]) == ["acc_1"]
  end

  test "get/2 fetches accommodation" do
    stub(fn conn ->
      assert conn.request_path == "/stays/accommodation/acc_1"
      Req.Test.json(conn, %{"data" => %{"id" => "acc_1"}})
    end)

    assert {:ok, %{"id" => "acc_1"}} = Accommodation.get(client(), "acc_1")
  end

  test "suggestions/2 posts a query" do
    stub(fn conn ->
      assert conn.method == "POST"
      assert conn.request_path == "/stays/accommodation/suggestions"

      {:ok, body, conn} = Plug.Conn.read_body(conn)
      assert %{"data" => %{"query" => "savoy"}} = Jason.decode!(body)

      Req.Test.json(conn, %{"data" => [%{"id" => "acc_1", "name" => "The Savoy"}]})
    end)

    assert {:ok, [%{"name" => "The Savoy"}]} =
             Accommodation.suggestions(client(), %{query: "savoy"})
  end

  test "reviews/3 returns the reviews object with pagination params" do
    stub(fn conn ->
      assert conn.request_path == "/stays/accommodation/acc_1/reviews"
      assert conn.query_params["limit"] == "5"
      Req.Test.json(conn, %{"data" => %{"reviews" => [%{"id" => "rev_1"}]}, "meta" => %{}})
    end)

    assert {:ok, %{"reviews" => [%{"id" => "rev_1"}]}} =
             Accommodation.reviews(client(), "acc_1", limit: 5)
  end

  test "reviews/2 defaults to no params" do
    stub(fn conn ->
      assert conn.request_path == "/stays/accommodation/acc_1/reviews"
      assert conn.query_string == ""
      Req.Test.json(conn, %{"data" => %{"reviews" => []}})
    end)

    assert {:ok, %{"reviews" => []}} = Accommodation.reviews(client(), "acc_1")
  end
end
