defmodule Duffel.OfferRequestsTest do
  use ExUnit.Case, async: true

  alias Duffel.{Error, OfferRequests, Page}

  defp client do
    Duffel.new(
      access_token: "duffel_test_abc",
      req_options: [plug: {Req.Test, __MODULE__}, retry: false]
    )
  end

  defp stub(fun), do: Req.Test.stub(__MODULE__, fun)

  describe "create/3" do
    test "posts to /air/offer_requests and unwraps data" do
      stub(fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/air/offer_requests"

        {:ok, body, conn} = Plug.Conn.read_body(conn)
        assert %{"data" => %{"cabin_class" => "economy"}} = Jason.decode!(body)

        Req.Test.json(conn, %{"data" => %{"id" => "orq_1", "live_mode" => false}})
      end)

      assert {:ok, %{"id" => "orq_1"}} =
               OfferRequests.create(client(), %{cabin_class: "economy"})
    end

    test "passes query params through" do
      stub(fn conn ->
        assert conn.query_params["return_offers"] == "false"
        Req.Test.json(conn, %{"data" => %{"id" => "orq_1"}})
      end)

      assert {:ok, _} =
               OfferRequests.create(client(), %{}, params: [return_offers: false])
    end

    test "returns the API error" do
      stub(fn conn ->
        conn
        |> Plug.Conn.put_status(422)
        |> Req.Test.json(%{"errors" => [%{"type" => "validation_error"}]})
      end)

      assert {:error, %Error{type: :validation_error}} = OfferRequests.create(client(), %{})
    end
  end

  describe "get/2" do
    test "fetches a single offer request" do
      stub(fn conn ->
        assert conn.method == "GET"
        assert conn.request_path == "/air/offer_requests/orq_1"
        Req.Test.json(conn, %{"data" => %{"id" => "orq_1"}})
      end)

      assert {:ok, %{"id" => "orq_1"}} = OfferRequests.get(client(), "orq_1")
    end
  end

  describe "list/2" do
    test "returns a page" do
      stub(fn conn ->
        assert conn.query_params["limit"] == "10"

        Req.Test.json(conn, %{
          "data" => [%{"id" => "orq_1"}],
          "meta" => %{"after" => nil, "limit" => 10}
        })
      end)

      assert {:ok, %Page{data: [%{"id" => "orq_1"}], after_cursor: nil}} =
               OfferRequests.list(client(), limit: 10)
    end

    test "defaults to no params" do
      stub(fn conn ->
        Req.Test.json(conn, %{"data" => [], "meta" => %{"after" => nil}})
      end)

      assert {:ok, %Page{data: []}} = OfferRequests.list(client())
    end
  end

  describe "stream/2" do
    test "streams across pages" do
      stub(fn conn ->
        case conn.query_params["after"] do
          nil ->
            Req.Test.json(conn, %{
              "data" => [%{"id" => "orq_1"}],
              "meta" => %{"after" => "cur_2"}
            })

          "cur_2" ->
            Req.Test.json(conn, %{
              "data" => [%{"id" => "orq_2"}],
              "meta" => %{"after" => nil}
            })
        end
      end)

      assert client() |> OfferRequests.stream() |> Enum.map(& &1["id"]) ==
               ["orq_1", "orq_2"]
    end
  end
end
