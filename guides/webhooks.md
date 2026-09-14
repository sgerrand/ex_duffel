# Webhooks

Manage subscriptions and verify incoming deliveries:

```elixir
{:ok, webhook} =
  Duffel.Webhooks.create(client, %{
    url: "https://example.com/webhooks/duffel",
    events: ["order.created", "order.airline_initiated_change_detected"]
  })

# The signing secret is only returned on creation — store it.
webhook["secret"]
```

In your endpoint, verify the `X-Duffel-Signature` header against the **raw
request body** before parsing:

```elixir
case Duffel.Webhooks.verify_signature(signature_header, raw_body, secret) do
  :ok -> handle_event(Jason.decode!(raw_body))
  {:error, _reason} -> send_resp(conn, 401, "")
end
```

Verification uses a constant-time comparison and rejects deliveries older
than 5 minutes (configurable via `:tolerance`).

## Keeping the raw body in Phoenix

`Plug.Parsers` reads and decodes the body before your controller runs, so
the raw bytes are gone by the time you need them. Give it a body reader
that keeps a copy:

```elixir
defmodule MyAppWeb.CacheBodyReader do
  # `:more` means the body is bigger than one read, so keep each chunk
  def read_body(conn, opts) do
    case Plug.Conn.read_body(conn, opts) do
      {status, body, conn} when status in [:ok, :more] ->
        conn = update_in(conn.assigns[:raw_body], &[body | &1 || []])
        {status, body, conn}

      error ->
        error
    end
  end
end
```

Add it to the `Plug.Parsers` call in your endpoint:

```elixir
plug Plug.Parsers,
  parsers: [:urlencoded, :multipart, :json],
  pass: ["*/*"],
  json_decoder: Phoenix.json_library(),
  body_reader: {MyAppWeb.CacheBodyReader, :read_body, []}
```

Then, in the controller:

```elixir
raw_body = conn.assigns.raw_body |> Enum.reverse() |> IO.iodata_to_binary()
signature_header = conn |> get_req_header("x-duffel-signature") |> List.first()
```

This keeps a copy of every request body. To keep it only for webhooks,
check `conn.request_path` in `read_body/2`.
