# Changelog

All notable changes to this project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
From the next release onward, entries below are generated automatically by
[release-please](https://github.com/googleapis/release-please) from
[Conventional Commits](https://www.conventionalcommits.org/).

## [0.1.1](https://github.com/sgerrand/ex_duffel/compare/v0.1.0...v0.1.1) (2026-06-10)


### Features

* **client:** emit telemetry span for requests ([9798978](https://github.com/sgerrand/ex_duffel/commit/97989780dee9c9bc54c1721203450eb2b58c5cf5))


### Documentation

* add CHANGELOG with 0.1.0 entry ([51c3831](https://github.com/sgerrand/ex_duffel/commit/51c383197c0a1c03658d6a77a833e6f9b963f29a))
* configure ExDoc ([032e166](https://github.com/sgerrand/ex_duffel/commit/032e166bb34cb798fe4f28685b840ef090346fa4))
* **readme:** add telemetry section ([c8757e0](https://github.com/sgerrand/ex_duffel/commit/c8757e0ac8885f9f44218eee8d1a35e6976e8c08))

## [0.1.0] - 2026-06-09

Initial release: an Elixir client for the Duffel API v2, built on
[Req](https://github.com/wojtekmach/req).

### Added

- HTTP client with bearer auth, the `Duffel-Version` header, gzip and
  automatic retries for rate-limited and transient errors.
- Explicit client struct (`Duffel.new/0` and `Duffel.new/1`) so multiple
  Duffel accounts can be used from one application.
- Cursor pagination via `Duffel.Page`, with a lazy `stream/2` on each list
  endpoint.
- Structured errors (`Duffel.Error`) with the API error type exposed as an
  atom for pattern matching.
- Flights: offer requests (standard, partial and batch), offers, seat maps,
  orders, payments, order cancellations, order change requests/offers/changes,
  airline-initiated changes and airline credits.
- Stays: search, accommodation, quotes, bookings, negotiated rates, brands,
  chains and loyalty programmes.
- Cars: search, quotes and bookings.
- Payments: card tokenisation on the PCI-scoped `api.duffel.cards` host and 3D
  Secure sessions.
- Identity: customer users, customer user groups and component client keys.
- Supporting data: airlines, airports, aircraft, cities, loyalty programmes
  and place suggestions.
- Webhooks: subscription management, event and delivery inspection, and
  signature verification with replay protection.

[0.1.0]: https://github.com/sgerrand/ex_duffel/releases/tag/v0.1.0
