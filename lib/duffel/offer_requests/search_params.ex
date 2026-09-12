defmodule Duffel.OfferRequests.SearchParams do
  @moduledoc """
  Build the request body for `Duffel.OfferRequests.create/3`.

  `new/1` assembles the params map and checks the required fields are
  present. `slice/4` and `passenger/1` build the journeys to search and
  the passengers travelling.

      params =
        Duffel.OfferRequests.SearchParams.new(
          slices: [
            Duffel.OfferRequests.SearchParams.slice("LHR", "JFK", "2026-07-01")
          ],
          passengers: [Duffel.OfferRequests.SearchParams.passenger(type: "adult")],
          cabin_class: "economy"
        )

      Duffel.OfferRequests.create(client, params)

  Using the builder is optional — `create/3` still accepts a plain map.
  """

  use Duffel.Params

  @required [:slices, :passengers]
  @optional [:cabin_class, :max_connections, :private_fares, :airline_credit_ids]
  @passenger_fields [
    :type,
    :age,
    :given_name,
    :family_name,
    :fare_type,
    :loyalty_programme_accounts
  ]

  @doc """
  Builds an offer request params map.

  Required: `:slices` and `:passengers`. Optional: `:cabin_class`,
  `:max_connections`, `:private_fares` and `:airline_credit_ids`. Raises
  `ArgumentError` if a required option is missing.
  """
  @spec new(keyword()) :: map()
  def new(opts) when is_list(opts) do
    require_params!(opts, @required)

    %{
      slices: Keyword.fetch!(opts, :slices),
      passengers: Keyword.fetch!(opts, :passengers)
    }
    |> put_params(opts, @optional)
  end

  @doc """
  Builds a slice (one leg of the journey) from `origin` and `destination`
  IATA codes and a `departure_date` (`YYYY-MM-DD`).

  Pass `:departure_time` or `:arrival_time` as `%{from: "09:00", to:
  "12:00"}` to restrict the times of day.
  """
  @spec slice(String.t(), String.t(), String.t(), keyword()) :: map()
  def slice(origin, destination, departure_date, opts \\ [])
      when is_binary(origin) and is_binary(destination) and is_binary(departure_date) do
    %{origin: origin, destination: destination, departure_date: departure_date}
    |> put_params(opts, [:departure_time, :arrival_time])
  end

  @doc """
  Builds a passenger. Accepts `:type` (`"adult"`, `"child"`,
  `"infant_without_seat"`) or `:age`, plus optional `:given_name`,
  `:family_name`, `:fare_type` and `:loyalty_programme_accounts`. Absent
  fields are omitted.
  """
  @spec passenger(keyword()) :: map()
  def passenger(opts \\ []) when is_list(opts) do
    put_params(%{}, opts, @passenger_fields)
  end
end
