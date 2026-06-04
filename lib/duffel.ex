defmodule Duffel do
  @moduledoc """
  An Elixir client for the [Duffel API](https://duffel.com/docs/api).

  ## Usage

  Build a client, then pass it to resource functions:

      client = Duffel.new(access_token: "duffel_test_...")

      {:ok, offer_request} =
        Duffel.OfferRequests.create(client, %{
          slices: [%{origin: "LHR", destination: "JFK", departure_date: "2026-07-01"}],
          passengers: [%{type: "adult"}],
          cabin_class: "economy"
        })

  ## Configuration

  `new/0` reads configuration from the application environment:

      config :duffel, access_token: System.fetch_env!("DUFFEL_ACCESS_TOKEN")

  Supported options (for `new/1` and the application environment):

    * `:access_token` - Duffel API access token (required)
    * `:base_url` - defaults to `"https://api.duffel.com"`
    * `:api_version` - value for the `Duffel-Version` header, defaults to `"v2"`
    * `:req_options` - extra options merged into every `Req` request
      (useful for timeouts or test stubs)

  """

  alias Duffel.Client

  @doc """
  Builds a client from the `:duffel` application environment.

  See the module documentation for supported configuration keys.
  """
  @spec new() :: Client.t()
  def new do
    :duffel
    |> Application.get_all_env()
    |> new()
  end

  @doc """
  Builds a client from the given options.

  ## Examples

      iex> client = Duffel.new(access_token: "duffel_test_abc")
      iex> client.api_version
      "v2"

  """
  @spec new(keyword()) :: Client.t()
  def new(opts) when is_list(opts) do
    Client.new(opts)
  end
end
