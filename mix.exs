defmodule WeatherStation.MixProject do
  use Mix.Project

  def project do
    [
      app: :weather_station,
      version: "0.1.0",
      elixir: "~> 1.7",
      build_embedded: true,
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {WeatherStation, []},
      extra_applications: [:crypto]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:animate, path: "../animate"},
      {:easing, path: "../easing", override: true},
      {:jason, "~> 1.3"},
      {:scenic, "~> 0.11.0-beta.0"},
      {:scenic_driver_local, "~> 0.11.0-beta.0", targets: :host},
      {:truetype_metrics, github: "boydm/truetype_metrics", branch: "master", override: true},
      {:tz, "~> 0.20.1"}
    ]
  end
end
