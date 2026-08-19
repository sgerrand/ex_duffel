defmodule Duffel.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/sgerrand/ex_duffel"

  def project do
    [
      app: :duffel,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [summary: [threshold: 100]],
      dialyzer: [
        plt_local_path: "_build/plts",
        plt_core_path: "_build/plts"
      ],
      name: "Duffel",
      description: "An Elixir library for the Duffel API",
      source_url: @source_url,
      docs: docs(),
      package: package()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      # Req is pre-1.0 and breaks between minor versions; only what CI runs.
      {:req, "~> 0.7"},
      {:telemetry, "~> 1.0"},
      # Used by the test suite to decode request bodies. Optional rather than
      # `only: :test` because Req depends on it outside the test environment,
      # and Mix rejects a dependency whose `:only` is narrower than its
      # parent's.
      {:jason, "~> 1.0", optional: true},
      {:plug, "~> 1.15", only: :test},
      {:ex_doc, "~> 0.26", only: :dev, runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      extras: ["README.md", "CHANGELOG.md", "LICENSE"],
      groups_for_modules: [
        Core: [
          Duffel,
          Duffel.Client,
          Duffel.Error,
          Duffel.Page,
          Duffel.RateLimit
        ],
        Schemas: [
          Duffel.Schema,
          Duffel.Schema.OfferRequest,
          Duffel.Schema.Offer,
          Duffel.Schema.Order,
          Duffel.Schema.Slice,
          Duffel.Schema.Segment,
          Duffel.Schema.Passenger,
          Duffel.Schema.Payment
        ],
        "Schemas — Stays": [
          Duffel.Schema.Stays.SearchResult,
          Duffel.Schema.Stays.Accommodation,
          Duffel.Schema.Stays.Room,
          Duffel.Schema.Stays.Rate,
          Duffel.Schema.Stays.Quote,
          Duffel.Schema.Stays.Booking
        ],
        "Schemas — Cars": [
          Duffel.Schema.Cars.Search,
          Duffel.Schema.Cars.Rate,
          Duffel.Schema.Cars.Quote,
          Duffel.Schema.Cars.Booking
        ],
        Flights: [
          Duffel.OfferRequests,
          Duffel.OfferRequests.SearchParams,
          Duffel.PartialOfferRequests,
          Duffel.BatchOfferRequests,
          Duffel.Offers,
          Duffel.SeatMaps,
          Duffel.Orders,
          Duffel.Orders.CreateParams,
          Duffel.Payments,
          Duffel.OrderCancellations,
          Duffel.OrderChangeRequests,
          Duffel.OrderChangeOffers,
          Duffel.OrderChanges,
          Duffel.AirlineInitiatedChanges,
          Duffel.AirlineCredits
        ],
        "Flights — Reference data": [
          Duffel.Airlines,
          Duffel.Airports,
          Duffel.Aircraft,
          Duffel.Cities,
          Duffel.LoyaltyProgrammes,
          Duffel.Places
        ],
        Stays: [
          Duffel.Stays.Search,
          Duffel.Stays.SearchParams,
          Duffel.Stays.Accommodation,
          Duffel.Stays.Quotes,
          Duffel.Stays.Bookings,
          Duffel.Stays.NegotiatedRates,
          Duffel.Stays.Brands,
          Duffel.Stays.Chains,
          Duffel.Stays.LoyaltyProgrammes
        ],
        Cars: [
          Duffel.Cars.Search,
          Duffel.Cars.SearchParams,
          Duffel.Cars.Quotes,
          Duffel.Cars.Bookings
        ],
        Payments: [
          Duffel.Cards,
          Duffel.ThreeDSecureSessions
        ],
        Identity: [
          Duffel.Identity.CustomerUsers,
          Duffel.Identity.CustomerUserGroups,
          Duffel.Identity.ComponentClientKeys
        ],
        Webhooks: [
          Duffel.Webhooks,
          Duffel.WebhookEvents,
          Duffel.WebhookDeliveries
        ]
      ]
    ]
  end

  def package do
    [
      files: ~w(.formatter.exs lib mix.exs README.md CHANGELOG.md LICENSE),
      licenses: ["BSD-2-Clause"],
      links: %{
        "GitHub" => @source_url,
        "Duffel API Docs" => "https://duffel.com/docs"
      }
    ]
  end
end
