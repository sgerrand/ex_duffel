# Stays

Booking accommodation takes four steps: search, fetch the full rates for a
result you like, turn a rate into a quote, then book the quote.

## 1. Search

`Duffel.Stays.SearchParams` builds the request. `:check_in_date`,
`:check_out_date` and `:guests` are required; `:rooms` defaults to 1.
Search either around a point or for accommodation you already know.

```elixir
alias Duffel.Stays.SearchParams

params =
  SearchParams.new(
    check_in_date: "2026-07-01",
    check_out_date: "2026-07-03",
    guests: [%{type: "adult"}, %{type: "child", age: 9}],
    rooms: 1,
    location: SearchParams.around(51.5074, -0.1278)
  )

{:ok, search} = Duffel.Stays.Search.create(client, params)
```

`around/3` takes a latitude, a longitude and a radius in kilometres,
which defaults to 5. To search named properties instead, pass
`accommodation: %{ids: ["acc_123"]}` in place of `:location`.

Each entry in `search["results"]` is one property, and carries only its
cheapest rate.

## 2. Fetch all rates

Pick a result and ask for its full rates. This takes the **search result**
id, not the search id.

```elixir
result = hd(search["results"])

{:ok, result} = Duffel.Stays.Search.fetch_all_rates(client, result["id"])

rate =
  result["rooms"]
  |> hd()
  |> Map.fetch!("rates")
  |> hd()
```

## 3. Quote

A quote confirms the price and holds it briefly.

```elixir
{:ok, stay_quote} = Duffel.Stays.Quotes.create(client, %{rate_id: rate["id"]})
```

## 4. Book

```elixir
{:ok, booking} =
  Duffel.Stays.Bookings.create(
    client,
    %{
      quote_id: stay_quote["id"],
      guests: [%{given_name: "Amelia", family_name: "Earhart"}],
      email: "amelia@duffel.com",
      phone_number: "+442080160508"
    },
    idempotency_key: "my-stay-reference"
  )

booking["reference"]
```

The ids chain together: a search result id (`ssr_`) gives you a rate id
(`rat_`), which gives you a quote id (`quo_`), which gives you a booking
(`bok_`).

## After booking

- `Duffel.Stays.Bookings.get/2` — fetch one booking.
- `Duffel.Stays.Bookings.list/2` and `stream/2` — page through bookings,
  optionally filtered by `:user_id`.
- `Duffel.Stays.Bookings.update/3` — change metadata or the customer users
  who may see it.
- `Duffel.Stays.Bookings.cancel/2` — cancel, subject to the rate's
  cancellation terms.
- `Duffel.Stays.Bookings.create_payment_instruction/3` — for postpaid
  bookings, pay with a card token. Only where the accommodation's
  `payment_instruction_supported` says so.

## Finding accommodation

- `Duffel.Stays.Accommodation.list/2` and `stream/2` — accommodation near a
  point. `:latitude` and `:longitude` are required, `:radius` is in
  kilometres (1 to 100, default 5).
- `Duffel.Stays.Accommodation.suggestions/2` — autocomplete a name, such as
  `%{query: "the savoy"}`, optionally within a location.
- `Duffel.Stays.Accommodation.reviews/3` — guest reviews for one property.
- `Duffel.Stays.Brands`, `Duffel.Stays.Chains` and
  `Duffel.Stays.LoyaltyProgrammes` — reference data.
- `Duffel.Stays.NegotiatedRates` — manage your own private rates, then
  search them with `negotiated_rate_ids:`.

## Typed responses

Every step returns a raw map. To get a struct instead, pass it to the
matching schema:

```elixir
result = Duffel.Schema.Stays.SearchResult.from_map(result)

result.accommodation.name
hd(result.accommodation.rooms).rates
```

`Duffel.Schema.Stays.Quote` and `Duffel.Schema.Stays.Booking` cover the
later steps. As elsewhere, decoding is shallow: an accommodation's
`location` or `brand` stays a raw map.
