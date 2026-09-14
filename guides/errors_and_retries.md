# Errors and retries

Every failure comes back as a `Duffel.Error`, so one clause covers both a
rejected request and a request that never reached Duffel. Errors from the
API mirror the [Duffel error schema](https://duffel.com/docs/api/overview/errors),
with `type` as an atom for pattern matching:

```elixir
case Duffel.Orders.create(client, params) do
  {:ok, order} ->
    order

  {:error, %Duffel.Error{type: :rate_limit_error}} ->
    retry_later()

  {:error, %Duffel.Error{type: :validation_error, source: source, message: message}} ->
    show_field_error(source, message)

  {:error, %Duffel.Error{type: :transport_error}} ->
    # the request failed to complete: connection refused, DNS, timeout.
    # Duffel may still have made the order, so look before retrying
    check_order_then_retry()

  {:error, %Duffel.Error{request_id: request_id}} ->
    # quote request_id when contacting Duffel support. It comes from the
    # response body, or the x-request-id header when the body has none
    log_and_fail(request_id)
end
```

A transport error has `status: nil` and keeps the underlying exception,
usually a `Req.TransportError`, under `reason`.

A 408, 429 or 503 is retried automatically, with a growing delay between
attempts. On a 429 or 503 the delay comes from `retry-after` when Duffel
sends it. A few network errors are retried too: a timeout, a refused or
closed connection, and an HTTP/2 request that was never sent. Other network
errors, such as an unreachable host, are not retried and come back
straight away as a `:transport_error`. Retries apply to every method,
`POST` included. 500 and 502 are never retried, because
Duffel documents them as "you should not retry this request", and a 504 is
retried only on a `GET` or `HEAD`. When a response reports your
remaining allowance, `Duffel.RateLimit` carries it — on the error, and on
every `[:duffel, :request, :stop]` telemetry event, so you can slow down
before Duffel starts refusing requests:

```elixir
{:error, %Duffel.Error{type: :rate_limit_error, rate_limit: rate_limit}} ->
  retry_in(rate_limit.retry_after_ms)
```

By default a `POST` carries an `Idempotency-Key` header. The client makes
one per call, and retries of that call reuse it. Pass your own with
`:idempotency_key`, or `idempotency_key: nil` to send none. Duffel does not
document how it treats the header, so it is best-effort: it may not stop a
duplicate.

This means a retried `POST` can still book twice. A timeout or dropped
connection can happen after Duffel has accepted the booking, and the
client has no way to tell. So if a create ends in a transport error or a
5xx, the result is unknown — the order may or may not exist. Check before
you try again.
