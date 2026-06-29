# Changelog

All notable changes to this project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
From the next release onward, entries below are generated automatically by
[release-please](https://github.com/googleapis/release-please) from
[Conventional Commits](https://www.conventionalcommits.org/).

## [0.1.0](https://github.com/sgerrand/ex_duffel/compare/v0.1.0...v0.1.0) (2026-06-29)


### Features

* **aic:** add AirlineInitiatedChanges resource ([22c2db0](https://github.com/sgerrand/ex_duffel/commit/22c2db04d4a0bb90f288f2eed5d318fd39c9af9e))
* **cancellations:** add OrderCancellations resource ([53b4935](https://github.com/sgerrand/ex_duffel/commit/53b493553da9fce33c0073ed31d11b49a869c782))
* **cars:** add Search, Quotes and Bookings resources ([29c2136](https://github.com/sgerrand/ex_duffel/commit/29c2136b3b6477a1b3d7f9d924339d85e1093371))
* **client:** add PUT and per-request host override ([187438d](https://github.com/sgerrand/ex_duffel/commit/187438d54450ea2e01029a6268c7462d63865fda))
* **client:** emit telemetry span for requests ([9798978](https://github.com/sgerrand/ex_duffel/commit/97989780dee9c9bc54c1721203450eb2b58c5cf5))
* **credits:** add AirlineCredits resource ([1ca9c2f](https://github.com/sgerrand/ex_duffel/commit/1ca9c2fe7afc62d7dec612db2ffc771c1e51c205))
* **identity:** add customer users, groups and component keys ([b46afc1](https://github.com/sgerrand/ex_duffel/commit/b46afc1ba5850bdd41353ad188113cd7338cab7a))
* **offers:** add Offers resource ([94617ab](https://github.com/sgerrand/ex_duffel/commit/94617ab829800d3c4eb79fce43a176f9410e48a3))
* **order-changes:** add order change flow resources ([6c1ae8e](https://github.com/sgerrand/ex_duffel/commit/6c1ae8eff75f06484cd01908ab491f168fd73007))
* **orders:** add Orders resource ([e82ff5f](https://github.com/sgerrand/ex_duffel/commit/e82ff5fe6e17a462eccca60bcf786ada237e1259))
* **payments:** add Cards and ThreeDSecureSessions ([6a5a834](https://github.com/sgerrand/ex_duffel/commit/6a5a834d2d7c087492e5d060aeb9e821a7e9fd98))
* **payments:** add Payments resource ([f154330](https://github.com/sgerrand/ex_duffel/commit/f1543300393726a0af0250b8a1622b4760ab3ab6))
* **pricing:** add price actions to Offers and Orders ([54de889](https://github.com/sgerrand/ex_duffel/commit/54de8892ca7b5e767d41ca87348fb27d00d98522))
* scaffold Duffel API client ([6065855](https://github.com/sgerrand/ex_duffel/commit/60658555c0a1f068e019e5a181e9507f69476874))
* **schema:** add opt-in typed response structs ([e717a5d](https://github.com/sgerrand/ex_duffel/commit/e717a5d207429b6f809c72ca44aca9586626a217))
* **search:** add Partial and Batch offer requests ([d0d6211](https://github.com/sgerrand/ex_duffel/commit/d0d621185f37f56fd807caaa9f2dbb0b18c61a47))
* **seat-maps:** add SeatMaps resource ([dc4a5db](https://github.com/sgerrand/ex_duffel/commit/dc4a5dbbe1a03b8daa17fdf6d1a820d415fba629))
* **stays,cars:** add search param builders ([06c11cd](https://github.com/sgerrand/ex_duffel/commit/06c11cd0b37222cb5cb761cb3933db607e4f20c3))
* **stays:** add NegotiatedRates and reference data ([f33917f](https://github.com/sgerrand/ex_duffel/commit/f33917f86034787603f06db93f2be5cc184f9126))
* **stays:** add Quotes and Bookings resources ([4b31aae](https://github.com/sgerrand/ex_duffel/commit/4b31aaeea72ea242a118368864d3a3741f5ace7d))
* **stays:** add Search and Accommodation resources ([3ba580a](https://github.com/sgerrand/ex_duffel/commit/3ba580ab195b755e4b9bf3a822f29712764d267c))
* **supporting-data:** add Airlines, Airports, Aircraft ([94c6585](https://github.com/sgerrand/ex_duffel/commit/94c6585dc82c1a5ba2b151631ac03a27526fce31))
* **supporting-data:** add Cities, LoyaltyProgrammes, Places ([7ad53ea](https://github.com/sgerrand/ex_duffel/commit/7ad53ea6cba2ca02e75faccc7c65d23eee40bb5f))
* **webhooks:** add WebhookEvents and WebhookDeliveries ([bb44267](https://github.com/sgerrand/ex_duffel/commit/bb44267ace9dd111346efe00e81a3b1d5392b2e0))
* **webhooks:** add Webhooks resource with signature verification ([c8fc1cb](https://github.com/sgerrand/ex_duffel/commit/c8fc1cbec8c73251281559f86cb35d74d45988ef))


### Bug Fixes

* align client with OpenAPI spec ([2f6373f](https://github.com/sgerrand/ex_duffel/commit/2f6373ff9930af9b4aca72ae54ece49205c310e8))
* **deps:** bump req from 0.5.18 to 0.6.1 ([#5](https://github.com/sgerrand/ex_duffel/issues/5)) ([ff91ceb](https://github.com/sgerrand/ex_duffel/commit/ff91ceb74394da4e35ced814d3726f81dd5ebf41))
* **deps:** bump req from 0.6.1 to 0.6.2 ([#7](https://github.com/sgerrand/ex_duffel/issues/7)) ([be8f605](https://github.com/sgerrand/ex_duffel/commit/be8f605983e7071e270fec82a550791586167d30))

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
