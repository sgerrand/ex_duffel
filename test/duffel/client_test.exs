defmodule Duffel.ClientTest.CaptureAdapter do
  @moduledoc false
  # Answers without a network round trip, reporting back the options Req was
  # given. Runs in the calling process, so the test receives the message.
  def run(request) do
    send(self(), {:options, request.options})
    {request, Req.Response.new(status: 200, body: %{"data" => %{}})}
  end
end

defmodule Duffel.ClientTest do
  use ExUnit.Case, async: true

  doctest Duffel.Client

  alias Duffel.{Client, Error, Page, RateLimit}

  defp client(opts \\ []) do
    Duffel.new(
      access_token: Keyword.get(opts, :access_token, "duffel_test_abc"),
      req_options: [plug: {Req.Test, __MODULE__}, retry: false]
    )
  end

  defp stub(fun), do: Req.Test.stub(__MODULE__, fun)

  describe "new/1" do
    test "hides the access token when the client is inspected" do
      inspected = inspect(client(access_token: "duffel_live_secret"))

      refute inspected =~ "duffel_live_secret"
      refute inspected =~ "access_token"
      assert inspected =~ "https://api.duffel.com"
    end

    test "waits longer than Duffel gives the airlines by default" do
      assert client().receive_timeout == 130_000
      assert Duffel.new(access_token: "t", receive_timeout: 90_000).receive_timeout == 90_000
    end

    test "keeps the access token readable on the struct" do
      assert client(access_token: "duffel_live_secret").access_token == "duffel_live_secret"
    end
  end

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

    test "generates an idempotency key for posts without one" do
      stub(fn conn ->
        assert [key] = Plug.Conn.get_req_header(conn, "idempotency-key")
        assert byte_size(key) >= 32
        Req.Test.json(conn, %{"data" => %{}})
      end)

      assert {:ok, _} = Client.post(client(), "/air/orders", %{})
    end

    test "generates a different key for each post" do
      test_pid = self()

      stub(fn conn ->
        [key] = Plug.Conn.get_req_header(conn, "idempotency-key")
        send(test_pid, {:key, key})
        Req.Test.json(conn, %{"data" => %{}})
      end)

      assert {:ok, _} = Client.post(client(), "/air/orders", %{})
      assert {:ok, _} = Client.post(client(), "/air/orders", %{})

      assert_received {:key, first}
      assert_received {:key, second}
      assert first != second
    end

    test "sends no idempotency key when it is nil" do
      stub(fn conn ->
        assert Plug.Conn.get_req_header(conn, "idempotency-key") == []
        Req.Test.json(conn, %{"data" => %{}})
      end)

      assert {:ok, _} = Client.post(client(), "/air/orders", %{}, idempotency_key: nil)
    end

    test "does not send an idempotency key on reads" do
      stub(fn conn ->
        assert Plug.Conn.get_req_header(conn, "idempotency-key") == []
        Req.Test.json(conn, %{"data" => %{}})
      end)

      assert {:ok, _} = Client.get(client(), "/air/orders")
    end

    test "reuses the same idempotency key when a post is retried" do
      test_pid = self()

      stub(fn conn ->
        [key] = Plug.Conn.get_req_header(conn, "idempotency-key")
        send(test_pid, {:key, key})

        case Process.get(:attempts, 0) do
          0 ->
            Process.put(:attempts, 1)
            conn |> Plug.Conn.put_status(503) |> Req.Test.json(%{"errors" => []})

          _retried ->
            Req.Test.json(conn, %{"data" => %{"id" => "ord_1"}})
        end
      end)

      retrying_client =
        Duffel.new(
          access_token: "duffel_test_abc",
          req_options: [plug: {Req.Test, __MODULE__}, retry_delay: 0, retry_log_level: false]
        )

      assert {:ok, %{"data" => %{"id" => "ord_1"}}} =
               Client.post(retrying_client, "/air/orders", %{})

      assert_received {:key, key}
      assert_received {:key, ^key}
    end
  end

  describe "retries" do
    defp retrying_client do
      Duffel.new(
        access_token: "duffel_test_abc",
        req_options: [plug: {Req.Test, __MODULE__}, retry_delay: 0, retry_log_level: false]
      )
    end

    defp counting_stub(status) do
      test_pid = self()

      stub(fn conn ->
        attempts = Process.get(:attempts, 0)
        Process.put(:attempts, attempts + 1)
        send(test_pid, :attempt)

        if attempts == 0 do
          conn |> Plug.Conn.put_status(status) |> Req.Test.json(%{"errors" => []})
        else
          Req.Test.json(conn, %{"data" => %{"id" => "ord_1"}})
        end
      end)
    end

    defp attempts do
      receive do
        :attempt -> 1 + attempts()
      after
        0 -> 0
      end
    end

    for status <- [408, 429, 503] do
      test "retries a #{status}" do
        counting_stub(unquote(status))

        assert {:ok, %{"data" => %{"id" => "ord_1"}}} =
                 Client.post(retrying_client(), "/air/orders", %{})

        assert attempts() == 2
      end
    end

    for status <- [500, 502] do
      test "does not retry a #{status}, which Duffel documents as not retryable" do
        counting_stub(unquote(status))

        assert {:error, %Duffel.Error{status: unquote(status)}} =
                 Client.post(retrying_client(), "/air/orders", %{})

        assert attempts() == 1
      end
    end

    test "retries a 504 on a read" do
      counting_stub(504)

      assert {:ok, %{"data" => %{"id" => "ord_1"}}} =
               Client.get(retrying_client(), "/air/orders/ord_1")

      assert attempts() == 2
    end

    test "does not retry a 504 on a post, which may have been processed" do
      counting_stub(504)

      assert {:error, %Duffel.Error{status: 504}} =
               Client.post(retrying_client(), "/air/orders", %{})

      assert attempts() == 1
    end
  end

  describe "patch/4 and put/4" do
    test "wrap the body in the data envelope" do
      stub(fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)

        Req.Test.json(conn, %{"data" => %{"method" => conn.method, "body" => Jason.decode!(body)}})
      end)

      assert {:ok, %{"data" => %{"method" => "PATCH", "body" => %{"data" => %{"a" => 1}}}}} =
               Client.patch(client(), "/air/orders/ord_1", %{a: 1})

      assert {:ok, %{"data" => %{"method" => "PUT", "body" => %{"data" => %{"a" => 1}}}}} =
               Client.put(client(), "/air/orders/ord_1", %{a: 1})
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

  describe "receive timeout" do
    defp capturing_client(opts, req_options \\ []) do
      req_options = Keyword.put(req_options, :adapter, Duffel.ClientTest.CaptureAdapter)

      Duffel.new(Keyword.put(opts, :req_options, req_options))
    end

    test "reaches Req" do
      assert {:ok, _} = Client.get(capturing_client(access_token: "t"), "/air/orders")
      assert_received {:options, %{receive_timeout: 130_000}}
    end

    test "can be raised on the client" do
      client = capturing_client(access_token: "t", receive_timeout: 90_000)

      assert {:ok, _} = Client.get(client, "/air/orders")
      assert_received {:options, %{receive_timeout: 90_000}}
    end

    test "is still overridden by req_options" do
      client =
        capturing_client([access_token: "t", receive_timeout: 90_000], receive_timeout: 1_000)

      assert {:ok, _} = Client.get(client, "/air/orders")
      assert_received {:options, %{receive_timeout: 1_000}}
    end
  end

  describe "query parameters" do
    test "sends one parameter per element of a list value" do
      stub(fn conn ->
        assert conn.query_string == "passenger_name%5B%5D=Amelia&passenger_name%5B%5D=Earhart"
        assert conn.params["passenger_name"] == ["Amelia", "Earhart"]
        Req.Test.json(conn, %{"data" => []})
      end)

      assert {:ok, _} =
               Client.list(client(), "/air/orders", %{
                 "passenger_name[]" => ["Amelia", "Earhart"]
               })
    end

    test "nests a map value as key[sub]" do
      stub(fn conn ->
        assert conn.params["departing_at"] == %{"after" => "2026-07-01T00:00:00Z"}
        assert conn.query_params["limit"] == "50"
        Req.Test.json(conn, %{"data" => []})
      end)

      assert {:ok, _} =
               Client.list(client(), "/air/orders",
                 departing_at: %{after: "2026-07-01T00:00:00Z"},
                 limit: 50
               )
    end

    test "nests every key of a map value" do
      stub(fn conn ->
        assert conn.params["created_at"] == %{
                 "after" => "2026-07-01T00:00:00Z",
                 "before" => "2026-07-31T00:00:00Z"
               }

        Req.Test.json(conn, %{"data" => []})
      end)

      assert {:ok, _} =
               Client.list(client(), "/air/orders",
                 created_at: %{after: "2026-07-01T00:00:00Z", before: "2026-07-31T00:00:00Z"}
               )
    end

    test "sends scalar parameters unchanged" do
      stub(fn conn ->
        assert conn.query_params == %{"limit" => "50", "sort" => "total_amount"}
        Req.Test.json(conn, %{"data" => []})
      end)

      assert {:ok, _} = Client.list(client(), "/air/offers", limit: 50, sort: "total_amount")
    end

    test "sends no query string when there are no parameters" do
      stub(fn conn ->
        assert conn.query_string == ""
        Req.Test.json(conn, %{"data" => %{}})
      end)

      assert {:ok, _} = Client.get(client(), "/air/orders/ord_1")
    end

    test "drops a parameter whose list is empty" do
      stub(fn conn ->
        assert conn.query_string == "limit=50"
        Req.Test.json(conn, %{"data" => []})
      end)

      assert {:ok, _} = Client.list(client(), "/air/orders", %{"limit" => 50, "tag[]" => []})
    end

    test "stream/3 replaces a caller's own after cursor rather than repeating it" do
      stub(fn conn ->
        case conn.query_string do
          "after=cur_1" ->
            Req.Test.json(conn, %{"data" => [%{"id" => "a"}], "meta" => %{"after" => "cur_2"}})

          "after=cur_2" ->
            Req.Test.json(conn, %{"data" => [%{"id" => "b"}], "meta" => %{"after" => nil}})
        end
      end)

      assert client() |> Client.stream("/air/orders", after: "cur_1") |> Enum.to_list() ==
               [%{"id" => "a"}, %{"id" => "b"}]
    end
  end

  describe "rate limits" do
    defp rate_limited_stub(headers) do
      stub(fn conn ->
        conn
        |> then(
          &Enum.reduce(headers, &1, fn {k, v}, acc -> Plug.Conn.put_resp_header(acc, k, v) end)
        )
        |> Plug.Conn.put_status(429)
        |> Req.Test.json(%{"errors" => [%{"type" => "rate_limit_error"}]})
      end)
    end

    test "are reported on the error" do
      rate_limited_stub([
        {"ratelimit-limit", "300"},
        {"ratelimit-remaining", "0"},
        {"ratelimit-reset", "2026-08-19T12:00:00Z"},
        {"retry-after", "12"}
      ])

      assert {:error, %Error{type: :rate_limit_error} = error} =
               Client.get(client(), "/air/orders")

      assert error.rate_limit == %RateLimit{
               limit: 300,
               remaining: 0,
               reset: "2026-08-19T12:00:00Z",
               retry_after_ms: 12_000
             }
    end

    test "ignore headers that are absent or unreadable" do
      rate_limited_stub([{"ratelimit-remaining", "not a number"}, {"ratelimit-limit", "300"}])

      assert {:error, %Error{rate_limit: rate_limit}} = Client.get(client(), "/air/orders")
      assert rate_limit == %RateLimit{limit: 300}
    end

    test "are nil when the response reports none" do
      rate_limited_stub([])

      assert {:error, %Error{rate_limit: nil}} = Client.get(client(), "/air/orders")
    end
  end

  describe "unwrap/1" do
    test "takes the resource out of the data envelope" do
      assert Client.unwrap({:ok, %{"data" => %{"id" => "ord_1"}}}) == {:ok, %{"id" => "ord_1"}}
    end

    test "errors on a success response with no data key" do
      assert {:error, %Error{} = error} = Client.unwrap({:ok, %{"meta" => %{"limit" => 50}}})
      assert error.type == :unexpected_response
      assert error.status == nil
      assert error.reason == %{"meta" => %{"limit" => 50}}
      assert Exception.message(error) =~ ~s(no "data" key)
    end

    test "errors on an empty success body" do
      assert {:error, %Error{type: :unexpected_response}} = Client.unwrap({:ok, ""})
    end

    test "passes errors through untouched" do
      error = {:error, %Error{type: :api_error}}
      assert Client.unwrap(error) == error
    end

    test "a resource returns the error when the envelope is missing" do
      stub(fn conn -> Req.Test.json(conn, %{"meta" => %{}}) end)

      assert {:error, %Error{type: :unexpected_response}} =
               Duffel.Orders.get(client(), "ord_1")
    end
  end

  describe "discard/1" do
    test "reports success without the body" do
      assert Client.discard({:ok, %{"data" => %{}}}) == :ok
      assert Client.discard({:ok, ""}) == :ok
    end

    test "passes errors through untouched" do
      error = {:error, %Error{type: :api_error}}
      assert Client.discard(error) == error
    end
  end

  describe "get_data/3, post_data/4, patch_data/4 and put_data/4" do
    setup do
      stub(fn conn ->
        Req.Test.json(conn, %{"data" => %{"method" => conn.method, "path" => conn.request_path}})
      end)
    end

    test "each performs its request and unwraps the resource" do
      assert Client.get_data(client(), "/air/orders") ==
               {:ok, %{"method" => "GET", "path" => "/air/orders"}}

      assert Client.post_data(client(), "/air/orders", %{}) ==
               {:ok, %{"method" => "POST", "path" => "/air/orders"}}

      assert Client.patch_data(client(), "/air/orders/ord_1", %{}) ==
               {:ok, %{"method" => "PATCH", "path" => "/air/orders/ord_1"}}

      assert Client.put_data(client(), "/air/orders/ord_1", %{}) ==
               {:ok, %{"method" => "PUT", "path" => "/air/orders/ord_1"}}
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

    test "falls back to the x-request-id header when the body carries no id" do
      stub(fn conn ->
        conn
        |> Plug.Conn.put_resp_header("x-request-id", "req_header_1")
        |> Plug.Conn.put_status(500)
        |> Req.Test.json(%{"errors" => [%{"type" => "api_error", "title" => "Server error"}]})
      end)

      assert {:error, %Error{request_id: "req_header_1", type: :api_error}} =
               Client.get(client(), "/air/orders")
    end

    test "prefers the request id in the body" do
      stub(fn conn ->
        conn
        |> Plug.Conn.put_resp_header("x-request-id", "req_header_1")
        |> Plug.Conn.put_status(422)
        |> Req.Test.json(%{
          "errors" => [%{"type" => "validation_error"}],
          "meta" => %{"request_id" => "req_body_1"}
        })
      end)

      assert {:error, %Error{request_id: "req_body_1"}} =
               Client.get(client(), "/air/orders")
    end

    test "reads the header when the error body is not the documented shape" do
      stub(fn conn ->
        conn
        |> Plug.Conn.put_resp_header("x-request-id", "req_header_2")
        |> Plug.Conn.put_status(502)
        |> Req.Test.json(%{"message" => "bad gateway"})
      end)

      assert {:error, %Error{request_id: "req_header_2", status: 502}} =
               Client.get(client(), "/air/orders")
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

    test "normalises transport errors into Duffel.Error" do
      stub(fn conn ->
        Req.Test.transport_error(conn, :econnrefused)
      end)

      assert {:error, %Error{} = error} = Client.get(client(), "/air/offers")
      assert error.type == :transport_error
      assert error.status == nil
      assert error.reason == %Req.TransportError{reason: :econnrefused}
      assert Exception.message(error) == "Duffel request failed: connection refused"
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

    test "stop carries the rate limit a successful response reported" do
      stub(fn conn ->
        conn
        |> Plug.Conn.put_resp_header("ratelimit-remaining", "42")
        |> Req.Test.json(%{"data" => %{}})
      end)

      assert {:ok, _} = Client.get(client(), "/air/offers")

      assert_received {:telemetry, [:duffel, :request, :stop], _measurements,
                       %{rate_limit: %RateLimit{remaining: 42}}}
    end

    test "stop reports nil status on transport errors" do
      stub(fn conn -> Req.Test.transport_error(conn, :econnrefused) end)

      assert {:error, _} = Client.get(client(), "/air/offers")

      assert_received {:telemetry, [:duffel, :request, :stop], _measurements,
                       %{status: nil, result: :error, rate_limit: nil}}
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

    test "list/3 errors when the body has no data list" do
      stub(fn conn -> Req.Test.json(conn, %{"meta" => %{"limit" => 50}}) end)

      assert {:error, %Error{type: :unexpected_response, reason: %{"meta" => _}}} =
               Client.list(client(), "/air/orders")
    end

    test "list/3 errors when data is not a list" do
      stub(fn conn -> Req.Test.json(conn, %{"data" => nil}) end)

      assert {:error, %Error{type: :unexpected_response}} = Client.list(client(), "/air/orders")
    end

    test "list/3 passes request errors through" do
      stub(fn conn ->
        conn |> Plug.Conn.put_status(422) |> Req.Test.json(%{"errors" => []})
      end)

      assert {:error, %Error{status: 422}} = Client.list(client(), "/air/orders")
    end

    test "stream/3 stops when Duffel hands back the cursor it was given" do
      stub(fn conn ->
        Req.Test.json(conn, %{
          "data" => [%{"id" => "orq_1"}],
          "meta" => %{"after" => "cur_stuck"}
        })
      end)

      assert_raise Error, ~r/same `after` cursor twice \("cur_stuck"\)/, fn ->
        client() |> Client.stream("/air/offer_requests", after: "cur_stuck") |> Enum.to_list()
      end
    end

    test "stream/3 still follows a cursor that differs from the one sent" do
      stub(fn conn ->
        case conn.query_params["after"] do
          nil ->
            Req.Test.json(conn, %{"data" => [%{"id" => "a"}], "meta" => %{"after" => "cur_2"}})

          "cur_2" ->
            Req.Test.json(conn, %{"data" => [%{"id" => "b"}], "meta" => %{"after" => nil}})
        end
      end)

      assert client() |> Client.stream("/air/offer_requests") |> Enum.to_list() ==
               [%{"id" => "a"}, %{"id" => "b"}]
    end

    test "stream/3 raises transport errors" do
      stub(fn conn ->
        Req.Test.transport_error(conn, :timeout)
      end)

      assert_raise Error, ~r/^Duffel request failed: timeout$/, fn ->
        client() |> Client.stream("/air/offer_requests") |> Enum.to_list()
      end
    end
  end
end
