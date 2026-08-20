# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Elixir client library (`:duffel` on Hex) for the Duffel flights API v2. Single runtime dependency: Req.

## Commands

```bash
mix deps.get                          # install dependencies
mix test                              # run all tests
mix test test/duffel/orders_test.exs  # one file
mix test test/duffel/orders_test.exs:42  # one test by line
mix format                            # format (run before committing)
mix docs                              # generate ExDoc docs
```

## Architecture

Three layers; everything funnels through `Duffel.Client`:

- `Duffel` (`lib/duffel.ex`) — entry point. `Duffel.new/1` builds a `%Duffel.Client{}` struct; `Duffel.new/0` reads the `:duffel` application environment. The client struct is passed explicitly to every resource function (multi-tenant by design; no global state).
- `Duffel.Client` (`lib/duffel/client.ex`) — Req-based transport. Owns: bearer auth, `Duffel-Version` header, gzip, `receive_timeout` (130s default — Duffel allows order/booking creation to take up to 120s and recommends a client timeout slightly above that; searches are quicker, so a search-only client can lower it), `retry: :transient` (auto-retries 429/5xx), the `data` request/response envelope, `Idempotency-Key` header (auto-generated on every `post`, overridable or disabled via the `:idempotency_key` opt), pagination (`list/3` → `Duffel.Page`, `stream/3` → lazy `Stream.resource` following `meta.after` cursors), query string encoding.
- Resource modules (`lib/duffel/*.ex`, plus `lib/duffel/{stays,cars,identity}/*.ex`) — thin, no macros. Each is a one-line call to `Client.get_data/post_data/patch_data/put_data` (request + take the resource out of the `"data"` envelope; a 2xx body without that key becomes an `:unexpected_response` error, never a silent pass-through), or to `Client.list/stream` for paginated endpoints (`list/3` errors the same way when `data` is missing or is not a list, rather than returning an empty page). Endpoints with no useful body pipe through `Client.discard/1` to return `:ok`. Reach for the raw `Client.get/post/put/patch/delete` plus `Client.unwrap/1` only when a resource has to build its request by hand. `lib/duffel/offer_requests.ex` is the canonical template for new resources.

Cross-cutting conventions:

- All calls return `{:ok, result} | {:error, %Duffel.Error{}}`. `Duffel.Error` is a `defexception` (returned in tuples normally, raised by `stream`). Its `type` field is an atom mapped from a whitelist; unknown API types become `:unknown_error`. Transport failures (connection refused, timeout) are normalised too, via `Error.from_exception/1`: `type: :transport_error`, `status: nil`, original exception under `:reason`. No raw `Req`/`Mint` exception ever reaches a caller. Rate-limit headers (`ratelimit-limit`/`-remaining`/`-reset`, `retry-after`) are parsed by `Duffel.RateLimit.from_response/1` onto `Error.rate_limit` and into `[:duffel, :request, :stop]` telemetry metadata; `openapi.yaml` does not document these headers, so parsing is tolerant and yields `nil` when they are absent.
- Resource functions return raw string-keyed maps. `Duffel.Schema.*` (`lib/duffel/schema/*.ex`) adds opt-in typed views over the core booking flow (OfferRequest, Offer, Order, Slice, Segment, Passenger, Payment): callers pass a map to `from_map/1` to get a struct. Decoding is shallow — only those seven types nest into structs; everything else stays a raw map. `from_map/1` is idempotent: it returns an already-decoded struct untouched, so add that clause to any new schema. Fields are sourced from the response schemas in `openapi.yaml`.
- Query strings are built by `Client.request/4` and appended to the path, not handed to Req's `:params`. Req keeps only the last value for a repeated key and renders a list value as one run-together string, neither of which can express Duffel's `key[]` array filters (`passenger_name[]`, `selected_partial_offer[]`). A list value sends one parameter per element.
- `Duffel.Page` uses `after_cursor`/`before_cursor` field names because `after` is a reserved word in Elixir (`page.after` won't parse).
- POST/PUT/PATCH bodies are wrapped in `%{data: body}` by `Client.post`/`Client.put`/`Client.patch`; callers pass the inner params only.
- Most endpoints use the main host. `Duffel.Cards` talks to the PCI-scoped `api.duffel.cards` host instead, via the client's `cards_base_url` and a `:base_url` override passed through to `Client.request/4`.
- `client.req_options` is merged last in `Client.request/4`, so it overrides everything — this is the seam tests use.
- `Duffel.Webhooks.verify_signature/4` is pure (no HTTP). It deliberately implements its own constant-time compare to avoid requiring OTP 25 (`:crypto.hash_equals`) or a runtime plug dependency. Plug is a test-only dep (needed by `Req.Test`).

## Tests

No network. Every test builds a client with `req_options: [plug: {Req.Test, __MODULE__}, retry: false]` and stubs responses with `Req.Test.stub/2` + `Req.Test.json/2`. All test modules are `async: true`. Follow this pattern for new resources; assert on `conn.request_path`, `conn.query_params`, and decoded request bodies in the stub.

When adding a resource, verify endpoint paths/params/bodies against `openapi.yaml` in the repo root (OpenAPI 3.1 spec of the Duffel v2 API) — it is the source of truth, more reliable than scraping the live docs. Resources are not uniformly RESTful (e.g. two-step cancellations/changes, action sub-paths like `/actions/confirm`; webhooks have no single-GET endpoint).

## Commits

Conventional Commits (`type(scope): subject`). Never add `Co-Authored-By` or any AI attribution. Commit lib + test file pairs together, one logical group per commit.
