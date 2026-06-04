defmodule Duffel.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :duffel,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "An Elixir library for the Duffel API",
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
      {:plug, "~> 1.15", only: :test},
      {:ex_doc, "~> 0.26", only: :dev, runtime: false}
    ]
  end

  def package do
    [
      files: ~w(.formatter.exs lib mix.exs README.md CHANGELOG.md LICENSE),
      licenses: ["BSD-2-Clause"],
      links: %{"API Docs" => "https://duffel.com/docs"}
    ]
  end
end
