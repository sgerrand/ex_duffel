defmodule Duffel.Stays.SearchParams do
  @moduledoc """
  Build the request body for `Duffel.Stays.Search.create/3`.

  `new/1` assembles the params map and checks the required fields are
  present; `around/3` builds a coordinate location to search within.

      params =
        Duffel.Stays.SearchParams.new(
          check_in_date: "2026-07-01",
          check_out_date: "2026-07-03",
          guests: [%{type: "adult"}],
          location: Duffel.Stays.SearchParams.around(51.5074, -0.1278)
        )

      Duffel.Stays.Search.create(client, params)

  Using the builder is optional — `create/3` still accepts a plain map.
  """

  @required [:check_in_date, :check_out_date, :guests]

  @doc """
  Builds a stays search params map.

  Required: `:check_in_date`, `:check_out_date`, `:guests`. `:rooms`
  defaults to `1`. Pass `:location` (see `around/3`) or `:accommodation`
  to scope the search. Raises `ArgumentError` if a required option is
  missing.
  """
  @spec new(keyword()) :: map()
  def new(opts) when is_list(opts) do
    require_keys(opts, @required)

    %{
      check_in_date: Keyword.fetch!(opts, :check_in_date),
      check_out_date: Keyword.fetch!(opts, :check_out_date),
      rooms: Keyword.get(opts, :rooms, 1),
      guests: Keyword.fetch!(opts, :guests)
    }
    |> maybe_put(:location, Keyword.get(opts, :location))
    |> maybe_put(:accommodation, Keyword.get(opts, :accommodation))
  end

  @doc """
  Builds a `location` value that searches within `radius` kilometres
  (default `5`) of the given coordinates.
  """
  @spec around(number(), number(), non_neg_integer()) :: map()
  def around(latitude, longitude, radius \\ 5)
      when is_number(latitude) and is_number(longitude) do
    %{
      radius: radius,
      geographic_coordinates: %{latitude: latitude, longitude: longitude}
    }
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
