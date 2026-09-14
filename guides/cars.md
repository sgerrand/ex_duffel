# Cars

Booking a rental car takes three steps: search, turn a rate into a quote,
then book the quote. Unlike Stays, the search response already carries
every rate, so there is no second fetch.

## 1. Search

`Duffel.Cars.SearchParams` builds the request. All seven options are
required, and anything else you pass is dropped. Dates are `YYYY-MM-DD`
and times are `HH:MM`.

```elixir
alias Duffel.Cars.SearchParams

params =
  SearchParams.new(
    driver: SearchParams.driver(age: 30, residence_country_code: "GB"),
    pickup_date: "2026-07-01",
    pickup_time: "10:00",
    pickup_location: SearchParams.at_airport("LHR"),
    dropoff_date: "2026-07-03",
    dropoff_time: "10:00",
    dropoff_location: SearchParams.at_coordinates(51.4700, -0.4543)
  )

{:ok, search} = Duffel.Cars.Search.create(client, params)

rate = hd(search["rates"])
```

Locations are either an airport, with `at_airport/1`, or a point, with
`at_coordinates/2`. You can mix the two: pick up at an airport and drop
off somewhere else.

The search driver is only an age and a country of residence, which is
what pricing depends on. It is a different shape from the driver you name
when booking, and `driver/1` quietly drops any other field, so a name
passed here never reaches Duffel.

## 2. Quote

```elixir
{:ok, car_quote} = Duffel.Cars.Quotes.create(client, %{rate_id: rate["id"]})
```

The quote carries `rate_id` and `search_id` back to where it came from.

## 3. Book

The booking driver is the person collecting the car, so it needs a name,
contact details and a date of birth.

```elixir
{:ok, booking} =
  Duffel.Cars.Bookings.create(
    client,
    %{
      quote_id: car_quote["id"],
      driver: %{
        given_name: "Amelia",
        family_name: "Earhart",
        email: "amelia@duffel.com",
        phone_number: "+442080160508",
        date_of_birth: "1987-07-24"
      }
    },
    idempotency_key: "my-car-reference"
  )

booking["reference"]
```

Add `supplier_loyalty_programme_account_number:` when the driver has a
membership with the supplier.

## After booking

`Duffel.Cars.Bookings.get/2` fetches a booking and
`Duffel.Cars.Bookings.cancel/2` cancels one. Cars has no list or update
endpoint, so keep your own record of the booking ids you create.

## Typed responses

Every step returns a raw map. To get a struct instead, pass it to the
matching schema:

```elixir
search = Duffel.Schema.Cars.Search.from_map(search)

hd(search.rates).total_amount
```

`Duffel.Schema.Cars.Quote` and `Duffel.Schema.Cars.Booking` cover the
later steps. Decoding is shallow, so a rate's `car` and `supplier` stay
raw maps.
