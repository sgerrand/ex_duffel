defmodule Duffel.MixProject do
  use Mix.Project

  @version "0.1.1"
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
      {:req, "~> 0.5"},
      {:telemetry, "~> 1.0"},
      {:plug, "~> 1.15", only: :test},
      {:ex_doc, "~> 0.26", only: :dev, runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
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
          Duffel.Page
        ],
        Flights: [
          Duffel.OfferRequests,
          Duffel.PartialOfferRequests,
          Duffel.BatchOfferRequests,
          Duffel.Offers,
          Duffel.SeatMaps,
          Duffel.Orders,
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
