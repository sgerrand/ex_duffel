defmodule Duffel.ClientTest do
  use ExUnit.Case, async: true

  alias Duffel.{Client, Error, Page}

  defp client(opts \\ []) do
    Duffel.new(
      access_token: Keyword.get(opts, :access_token, "duffel_test_abc"),
      req_options: [plug: {Req.Test, __MODULE__}, retry: false]
    )
  end

  defp stub(fun), do: Req.Test.stub(__MODULE__, fun)

  describe "request headers" do
    test "sends auth, version and accept headers" do
      stub(fn conn ->
        assert Plug.Conn.get_req_header(conn, "authorization") == ["Bearer duffel_test_abc"]
        assert Plug.Conn.get_req_header(conn, "duffel-version") == ["v2"]
        assert Plug.Conn.get_req_header(conn, "accept") == ["application/json"]
        Req.Test.json(conn, %{"data" => %{}})
      end)

      assert {:ok, _} = Client.get(client(), "/air/offers")
    end

    test "sends the idempotency key header when given" do
      stub(fn conn ->
        assert Plug.Conn.get_req_header(conn, "idempotency-key") == ["key-123"]
        Req.Test.json(conn, %{"data" => %{}})
      end)

      assert {:ok, _} =
               Client.post(client(), "/air/orders", %{}, idempotency_key: "key-123")
    end
  end

  describe "post/4" do
    test "wraps the body in the data envelope" do
      stub(fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        assert Jason.decode!(body) == %{"data" => %{"cabin_class" => "economy"}}
        Req.Test.json(conn, %{"data" => %{"id" => "orq_1"}})
      end)

      assert {:ok, %{"data" => %{"id" => "orq_1"}}} =
               Client.post(client(), "/air/offer_requests", %{cabin_class: "economy"})
    end
  end

  describe "error handling" do
    test "parses a Duffel error response" do
      stub(fn conn ->
        conn
        |> Plug.Conn.put_status(422)
        |> Req.Test.json(%{
          "errors" => [
            %{
              "type" => "validation_error",
              "code" => "missing_field",
              "title" => "Missing field",
              "message" => "slices is required",
              "documentation_url" => "https://duffel.com/docs",
              "source" => %{"field" => "slices", "pointer" => "/slices"}
            }
          ],
          "meta" => %{"request_id" => "req_123", "status" => 422}
        })
      end)

      assert {:error, %Error{} = error} = Client.post(client(), "/air/offer_requests", %{})
      assert error.type == :validation_error
      assert error.code == "missing_field"
      assert error.message == "slices is required"
      assert error.source == %{"field" => "slices", "pointer" => "/slices"}
      assert error.request_id == "req_123"
      assert error.status == 422
      assert [_] = error.errors
      assert Exception.message(error) =~ "HTTP 422"
    end

    test "maps unknown error types to :unknown_error" do
      stub(fn conn ->
        conn
        |> Plug.Conn.put_status(500)
        |> Req.Test.json(%{"errors" => [%{"type" => "brand_new_error"}]})
      end)

      assert {:error, %Error{type: :unknown_error, status: 500}} =
               Client.get(client(), "/air/offers")
    end

    test "handles non-JSON error bodies" do
      stub(fn conn ->
        Plug.Conn.send_resp(conn, 502, "Bad Gateway")
      end)

      assert {:error, %Error{status: 502, errors: []}} = Client.get(client(), "/air/offers")
    end

    test "returns transport errors as exceptions" do
      stub(fn conn ->
        Req.Test.transport_error(conn, :econnrefused)
      end)

      assert {:error, %Req.TransportError{reason: :econnrefused}} =
               Client.get(client(), "/air/offers")
    end

    test "exception/1 builds an error struct" do
      assert %Error{type: :api_error} = Error.exception(type: :api_error)
      assert Exception.message(%Error{}) =~ "unknown error"
    end
  end

  describe "request/4" do
    test "defaults opts to an empty list" do
      stub(fn conn -> Req.Test.json(conn, %{"data" => %{}}) end)

      assert {:ok, %{"data" => %{}}} = Client.request(client(), :get, "/air/offers")
    end
  end

  describe "telemetry" do
    setup do
      ref = make_ref()

      events = [
        [:duffel, :request, :start],
        [:duffel, :request, :stop],
        [:duffel, :request, :exception]
      ]

      :telemetry.attach_many(
        {__MODULE__, ref},
        events,
        fn event, measurements, metadata, _config ->
          send(self(), {:telemetry, event, measurements, metadata})
        end,
        nil
      )

      on_exit(fn -> :telemetry.detach({__MODULE__, ref}) end)
      :ok
    end

    test "emits start and stop with metadata on success" do
      stub(fn conn -> Req.Test.json(conn, %{"data" => %{}}) end)

      assert {:ok, _} = Client.get(client(), "/air/offers")

      assert_received {:telemetry, [:duffel, :request, :start], %{system_time: _},
                       %{method: :get, path: "/air/offers", base_url: "https://api.duffel.com"}}

      assert_received {:telemetry, [:duffel, :request, :stop], %{duration: _},
                       %{status: 200, result: :ok}}
    end

    test "stop carries error result and status for API errors" do
      stub(fn conn ->
        conn
        |> Plug.Conn.put_status(422)
        |> Req.Test.json(%{"errors" => [%{"type" => "validation_error"}]})
      end)

      assert {:error, _} = Client.post(client(), "/air/orders", %{})

      assert_received {:telemetry, [:duffel, :request, :stop], _measurements,
                       %{status: 422, result: :error}}
    end

    test "stop reports nil status on transport errors" do
      stub(fn conn -> Req.Test.transport_error(conn, :econnrefused) end)

      assert {:error, _} = Client.get(client(), "/air/offers")

      assert_received {:telemetry, [:duffel, :request, :stop], _measurements,
                       %{status: nil, result: :error}}
    end
  end

  describe "list/3 and stream/3" do
    test "list/3 returns a page with cursors" do
      stub(fn conn ->
        Req.Test.json(conn, %{
          "data" => [%{"id" => "orq_1"}],
          "meta" => %{"after" => "cur_2", "before" => nil, "limit" => 50}
        })
      end)

      assert {:ok, %Page{} = page} = Client.list(client(), "/air/offer_requests")
      assert page.data == [%{"id" => "orq_1"}]
      assert page.after_cursor == "cur_2"
      assert page.limit == 50
    end

    test "stream/3 follows after cursors until exhausted" do
      stub(fn conn ->
        case conn.query_params["after"] do
          nil ->
            Req.Test.json(conn, %{
              "data" => [%{"id" => "orq_1"}, %{"id" => "orq_2"}],
              "meta" => %{"after" => "cur_2", "limit" => 2}
            })

          "cur_2" ->
            Req.Test.json(conn, %{
              "data" => [%{"id" => "orq_3"}],
              "meta" => %{"after" => nil, "limit" => 2}
            })
        end
      end)

      ids =
        client()
        |> Client.stream("/air/offer_requests", limit: 2)
        |> Enum.map(& &1["id"])

      assert ids == ["orq_1", "orq_2", "orq_3"]
    end

    test "stream/3 raises on error responses" do
      stub(fn conn ->
        conn
        |> Plug.Conn.put_status(429)
        |> Req.Test.json(%{"errors" => [%{"type" => "rate_limit_error"}]})
      end)

      assert_raise Error, ~r/HTTP 429/, fn ->
        client() |> Client.stream("/air/offer_requests") |> Enum.to_list()
      end
    end

    test "stream/3 raises transport errors" do
      stub(fn conn ->
        Req.Test.transport_error(conn, :timeout)
      end)

      assert_raise Req.TransportError, fn ->
        client() |> Client.stream("/air/offer_requests") |> Enum.to_list()
      end
    end
  end
end
