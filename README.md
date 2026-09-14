# Duffel

An Elixir client for the [Duffel API](https://duffel.com/docs/api) — search,
book and manage flights.

## Installation

Needs Elixir 1.15 or later. Talks to version 2 of the Duffel API.

Add `duffel` to your list of dependencies in `mix.exs`:

<!-- x-release-please-start-version -->

```elixir
def deps do
  [
    {:duffel, "~> 0.1.1"}
  ]
end
```

<!-- x-release-please-end -->

## Getting started

Grab an access token from the [Duffel dashboard](https://app.duffel.com/) and
build a client:

```elixir
client = Duffel.new(access_token: "duffel_test_...")
```

Or configure it once and use `Duffel.new/0`:

```elixir
# config/runtime.exs
config :duffel, access_token: System.fetch_env!("DUFFEL_ACCESS_TOKEN")

client = Duffel.new()
```

Test mode and live mode use the same API — only the token differs. Clients
are plain structs, so multi-tenant apps can hold one per Duffel account.

`Duffel.new/1` also takes `:base_url`, `:cards_base_url`, `:api_version`,
`:receive_timeout` and `:req_options`. A request waits 130 seconds for a response, which
covers the 120 seconds Duffel allows order and booking creation to take.
Searching is much quicker — each airline gets 20 seconds to answer by
default, up to the 60 seconds `supplier_timeout` allows — so lower it on a
client used only for searching:

```elixir
client = Duffel.new(access_token: token, receive_timeout: 30_000)
```

Every call returns `{:ok, result}` or `{:error, %Duffel.Error{}}`. See
[Errors and retries](guides/errors_and_retries.md) for the error types,
what gets retried, and rate limits.

## Searching and booking flights

```elixir
# 1. Search: create an offer request. `return_offers: false` leaves the
#    offers out of this response, so step 2 fetches them only once.
{:ok, offer_request} =
  Duffel.OfferRequests.create(
    client,
    %{
      slices: [
        %{origin: "LHR", destination: "JFK", departure_date: "2026-07-01"}
      ],
      passengers: [%{type: "adult"}],
      cabin_class: "economy"
    },
    params: [return_offers: false]
  )

# 2. Pick an offer: list them, cheapest first
{:ok, page} =
  Duffel.Offers.list(client,
    offer_request_id: offer_request["id"],
    sort: "total_amount"
  )

offer = hd(page.data)

# 3. Book: create an order
{:ok, order} =
  Duffel.Orders.create(
    client,
    %{
      selected_offers: [offer["id"]],
      passengers: [
        %{
          id: hd(offer["passengers"])["id"],
          title: "ms",
          given_name: "Amelia",
          family_name: "Earhart",
          born_on: "1987-07-24",
          email: "amelia@duffel.com",
          phone_number: "+442080160508"
        }
      ],
      payments: [
        %{
          type: "balance",
          currency: offer["total_currency"],
          amount: offer["total_amount"]
        }
      ]
    },
    idempotency_key: "my-booking-reference"
  )

order["booking_reference"]
#=> "RZPNX8"
```

`:idempotency_key` is optional — see
[Errors and retries](guides/errors_and_retries.md).

## Pagination

List endpoints return one `Duffel.Page` at a time:

```elixir
{:ok, page} = Duffel.Orders.list(client, limit: 100)
page.data          # results
page.after_cursor  # pass as `after:` for the next page; nil on the last page
```

To walk the pages yourself, `Duffel.Page.has_more?/1` and
`Duffel.Page.next_params/2` do the cursor bookkeeping — `next_params/2`
keeps your filters and returns `nil` on the last page:

```elixir
case Duffel.Page.next_params(page, limit: 100) do
  nil -> :done
  params -> Duffel.Orders.list(client, params)
end
```

Or stream every result lazily — pages are fetched as needed:

```elixir
client
|> Duffel.Orders.stream(awaiting_payment: true)
|> Enum.take(500)
```

Streams raise `Duffel.Error` on request failure.

## Typed responses

Resource functions return raw string-keyed maps. When you want a struct
with named fields instead, pass the map to the matching schema's
`from_map/1`:

```elixir
{:ok, order} = Duffel.Orders.get(client, "ord_123")
order = Duffel.Schema.Order.from_map(order)

order.booking_reference
#=> "RZPNX8"

# nested resources are decoded too
hd(order.slices).segments
#=> [%Duffel.Schema.Segment{...}, ...]
```

Schemas cover three areas:

- **Flights** — `Duffel.Schema.OfferRequest`, `Offer`, `Order`, `Slice`,
  `Segment`, `Passenger` and `Payment`. A search asked for with
  `view: "itineraries"` has its own schema, `Duffel.Schema.ItineraryView`,
  which groups offers by itinerary and fare brand and resolves the
  airlines, places and aircraft that shape names by ID.
- **Stays** — `Duffel.Schema.Stays.SearchResult`, `Accommodation`, `Room`,
  `Rate`, `Quote` and `Booking`.
- **Cars** — `Duffel.Schema.Cars.Search`, `Rate`, `Quote` and `Booking`.

Decoding is opt-in and shallow: fields without their own schema (such as an
offer's `owner` airline, or a car's `supplier`) stay raw maps. Map over a
page's data to decode a list:

```elixir
{:ok, page} = Duffel.Orders.list(client)
orders = Enum.map(page.data, &Duffel.Schema.Order.from_map/1)
```

## Telemetry

Every request emits a [`telemetry`](https://hexdocs.pm/telemetry) span
under the `[:duffel, :request]` prefix — `:start`, `:stop` and
`:exception` events. Metadata carries `:method`, `:path` and `:base_url`;
the `:stop` event also reports `:status`, `:result` (`:ok` or `:error`)
and `:rate_limit`. Attach a handler to measure latency or log requests:

```elixir
:telemetry.attach(
  "duffel-logger",
  [:duffel, :request, :stop],
  fn _event, %{duration: duration}, meta, _config ->
    ms = System.convert_time_unit(duration, :native, :millisecond)
    Logger.info("duffel #{meta.method} #{meta.path} -> #{meta.status} (#{ms}ms)")
  end,
  nil
)
```

## Guides

- [Errors and retries](guides/errors_and_retries.md) — error types, the
  retry policy, rate limits and idempotency keys.
- [Webhooks](guides/webhooks.md) — subscriptions, signature checks and
  keeping the raw body in Phoenix.
- [Stays](guides/stays.md) — search, quote and book accommodation.
- [Cars](guides/cars.md) — search, quote and book rental cars.
- [Testing your app](guides/testing.md) — stub Duffel with `Req.Test`,
  including error and transport failures.

## Resources

### Flights

| Module | Duffel resource |
| --- | --- |
| `Duffel.OfferRequests` | Search for flights |
| `Duffel.OfferRequests.SearchParams` | Build a flight search request |
| `Duffel.PartialOfferRequests` | Multi-step (per-slice) search |
| `Duffel.BatchOfferRequests` | Batched search with polling |
| `Duffel.Offers` | Offers returned by a search, re-pricing, upsells |
| `Duffel.SeatMaps` | Seat maps for an offer |
| `Duffel.Orders` | Bookings, services, metadata, re-pricing |
| `Duffel.Orders.CreateParams` | Build an order request |
| `Duffel.Payments` | Pay for hold orders |
| `Duffel.OrderCancellations` | Two-step cancellation with refund preview |
| `Duffel.OrderChangeRequests` | Request changes to an order |
| `Duffel.OrderChangeOffers` | Offers for a change request |
| `Duffel.OrderChanges` | Apply and confirm a change |
| `Duffel.AirlineInitiatedChanges` | Handle schedule changes |
| `Duffel.AirlineCredits` | Credits issued to customer users |
| `Duffel.Webhooks` | Subscriptions + signature verification |
| `Duffel.WebhookEvents` / `Duffel.WebhookDeliveries` | Event inspection, redelivery |
| `Duffel.Airlines` / `Duffel.Airports` / `Duffel.Aircraft` / `Duffel.Cities` | Reference data |
| `Duffel.LoyaltyProgrammes` | Loyalty programme reference data |
| `Duffel.Places` | Airport/city autocomplete |

### Stays

| Module | Duffel resource |
| --- | --- |
| `Duffel.Stays.Search` | Search accommodation, fetch all rates |
| `Duffel.Stays.SearchParams` | Build a stays search request |
| `Duffel.Stays.Accommodation` | Lookup, suggestions, reviews |
| `Duffel.Stays.Quotes` | Confirm a rate before booking |
| `Duffel.Stays.Bookings` | Book, manage, cancel, payment instructions |
| `Duffel.Stays.NegotiatedRates` | Manage private rates |
| `Duffel.Stays.Brands` / `Duffel.Stays.Chains` | Reference data |
| `Duffel.Stays.LoyaltyProgrammes` | Loyalty programme reference data |

The Stays booking flow: search → `fetch_all_rates` → create a quote →
create a booking from the quote. See the [Stays guide](guides/stays.md).

### Cars

| Module | Duffel resource |
| --- | --- |
| `Duffel.Cars.Search` | Search for rental cars |
| `Duffel.Cars.SearchParams` | Build a cars search request |
| `Duffel.Cars.Quotes` | Confirm a rate before booking |
| `Duffel.Cars.Bookings` | Book, retrieve, cancel |

The Cars booking flow: search → create a quote → create a booking from
the quote. See the [Cars guide](guides/cars.md).

### Payments

| Module | Duffel resource |
| --- | --- |
| `Duffel.Cards` | Tokenise cards (PCI-scoped `api.duffel.cards` host) |
| `Duffel.ThreeDSecureSessions` | 3DS sessions for card payments |

`Duffel.Cards` talks to `api.duffel.cards`, set via `:cards_base_url` on
the client. Card tokens are single-use and short-lived.

### Identity

| Module | Duffel resource |
| --- | --- |
| `Duffel.Identity.CustomerUsers` | Travellers and bookers |
| `Duffel.Identity.CustomerUserGroups` | Group users for access scoping |
| `Duffel.Identity.ComponentClientKeys` | Browser keys for Duffel UI components |

## Documentation

Full documentation at <https://hexdocs.pm/duffel>.

## License

BSD 2-Clause. See [LICENSE](LICENSE).
