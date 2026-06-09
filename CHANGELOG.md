# Changelog

All notable changes to this project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
From the next release onward, entries below are generated automatically by
[release-please](https://github.com/googleapis/release-please) from
[Conventional Commits](https://www.conventionalcommits.org/).

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
