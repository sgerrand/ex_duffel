# Testing your app

The client accepts `req_options`, so you can stub HTTP with
[`Req.Test`](https://hexdocs.pm/req/Req.Test.html) — no network needed.
`Req.Test` needs Plug. Phoenix apps already have it; otherwise add
`{:plug, "~> 1.0", only: :test}` to your dependencies.

```elixir
client =
  Duffel.new(
    access_token: "duffel_test_fake",
    req_options: [plug: {Req.Test, MyApp.DuffelStub}, retry: false]
  )

Req.Test.stub(MyApp.DuffelStub, fn conn ->
  Req.Test.json(conn, %{"data" => %{"id" => "ord_1"}})
end)
```

`retry: false` stops the client retrying a stubbed 429 or 503, which
would slow your tests down.

To test your error handling, stub an error response in Duffel's shape:

```elixir
Req.Test.stub(MyApp.DuffelStub, fn conn ->
  conn
  |> Plug.Conn.put_status(422)
  |> Req.Test.json(%{
    "errors" => [
      %{
        "type" => "validation_error",
        "code" => "missing_field",
        "title" => "Missing field",
        "message" => "slices is required"
      }
    ]
  })
end)

{:error, %Duffel.Error{type: :validation_error, status: 422}} =
  Duffel.OfferRequests.create(client, %{})
```

`Req.Test.transport_error(conn, :timeout)` stands in for a request that
never reached Duffel, and comes back as a `:transport_error`.
