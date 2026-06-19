defmodule Duffel.Cars.SearchParams do
  @moduledoc """
  Build the request body for `Duffel.Cars.Search.create/3`.

  `new/1` assembles the params map and checks the required fields are
  present. `driver/1`, `at_airport/1` and `at_coordinates/2` build the
  nested driver and location values.

      params =
        Duffel.Cars.SearchParams.new(
          driver: Duffel.Cars.SearchParams.driver(age: 30),
          pickup_date: "2026-07-01",
          pickup_time: "10:00",
          pickup_location: Duffel.Cars.SearchParams.at_airport("LHR"),
          dropoff_date: "2026-07-03",
          dropoff_time: "10:00",
          dropoff_location: Duffel.Cars.SearchParams.at_airport("LHR")
        )

      Duffel.Cars.Search.create(client, params)

  Using the builder is optional — `create/3` still accepts a plain map.
  """

  @required [
    :driver,
    :pickup_date,
    :pickup_time,
    :pickup_location,
    :dropoff_date,
    :dropoff_time,
    :dropoff_location
  ]

  @driver_fields [:age, :given_name, :family_name, :email, :phone_number]

  @doc """
  Builds a cars search params map.

  All of `:driver`, `:pickup_date`, `:pickup_time`, `:pickup_location`,
  `:dropoff_date`, `:dropoff_time` and `:dropoff_location` are required.
  Dates are `YYYY-MM-DD` and times are `HH:MM`. Raises `ArgumentError` if
  a required option is missing.
  """
  @spec new(keyword()) :: map()
  def new(opts) when is_list(opts) do
    require_keys(opts, @required)
    Map.new(@required, fn key -> {key, Keyword.fetch!(opts, key)} end)
  end

  @doc """
  Builds a `driver` value. Accepts `:age`, `:given_name`, `:family_name`,
  `:email` and `:phone_number`; absent fields are omitted.
  """
  @spec driver(keyword()) :: map()
  def driver(opts \\ []) when is_list(opts) do
    Enum.reduce(@driver_fields, %{}, fn key, acc ->
      maybe_put(acc, key, Keyword.get(opts, key))
    end)
  end

  @doc "Builds a pickup or dropoff location at an airport by IATA code."
  @spec at_airport(String.t()) :: map()
  def at_airport(iata_code) when is_binary(iata_code), do: %{iata_code: iata_code}

  @doc "Builds a pickup or dropoff location at geographic coordinates."
  @spec at_coordinates(number(), number()) :: map()
  def at_coordinates(latitude, longitude)
      when is_number(latitude) and is_number(longitude) do
    %{geographic_coordinates: %{latitude: latitude, longitude: longitude}}
  end

  defp require_keys(opts, keys) do
    case Enum.reject(keys, &Keyword.has_key?(opts, &1)) do
      [] -> :ok
      missing -> raise ArgumentError, "missing required options: #{inspect(missing)}"
    end
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
