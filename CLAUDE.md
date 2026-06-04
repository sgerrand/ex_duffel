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
- `Duffel.Client` (`lib/duffel/client.ex`) — Req-based transport. Owns: bearer auth, `Duffel-Version` header, gzip, `retry: :transient` (auto-retries 429/5xx), the `data` request/response envelope, `Idempotency-Key` header (via `:idempotency_key` opt on `post`), pagination (`list/3` → `Duffel.Page`, `stream/3` → lazy `Stream.resource` following `meta.after` cursors).
- Resource modules (`lib/duffel/*.ex`) — thin, no macros. Each wraps `Client.get/post/patch/delete/list/stream` and unwraps the response `"data"` key. `lib/duffel/offer_requests.ex` is the canonical template for new resources.

Cross-cutting conventions:

- All calls return `{:ok, result} | {:error, %Duffel.Error{}}`. `Duffel.Error` is a `defexception` (returned in tuples normally, raised by `stream`). Its `type` field is an atom mapped from a whitelist; unknown API types become `:unknown_error`.
- Responses are raw string-keyed maps — no typed structs (deliberate; revisit per-resource if needed).
- `Duffel.Page` uses `after_cursor`/`before_cursor` field names because `after` is a reserved word in Elixir (`page.after` won't parse).
- POST/PATCH bodies are wrapped in `%{data: body}` by `Client.post`/`Client.patch`; callers pass the inner params only.
- `client.req_options` is merged last in `Client.request/4`, so it overrides everything — this is the seam tests use.
- `Duffel.Webhooks.verify_signature/4` is pure (no HTTP). It deliberately implements its own constant-time compare to avoid requiring OTP 25 (`:crypto.hash_equals`) or a runtime plug dependency. Plug is a test-only dep (needed by `Req.Test`).

## Tests

No network. Every test builds a client with `req_options: [plug: {Req.Test, __MODULE__}, retry: false]` and stubs responses with `Req.Test.stub/2` + `Req.Test.json/2`. All test modules are `async: true`. Follow this pattern for new resources; assert on `conn.request_path`, `conn.query_params`, and decoded request bodies in the stub.

When adding a resource, verify endpoint paths/params against the live Duffel v2 docs (https://duffel.com/docs/api) first — resources are not uniformly RESTful (e.g. two-step cancellations/changes, action sub-paths like `/actions/confirm`).

## Commits

Conventional Commits (`type(scope): subject`). Never add `Co-Authored-By` or any AI attribution. Commit lib + test file pairs together, one logical group per commit.
