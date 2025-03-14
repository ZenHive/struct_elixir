defmodule EtheriumApi.MixProject do
  use Mix.Project

  def project do
    [
      app: :etherium_api,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: [
        flags: [
          :unmatched_returns,
          :extra_return,
          :missing_return,
          :unmatched_returns
        ]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:dialyxir, "~> 1.4", only: [:dev], runtime: false},
      {:httpoison, "~> 2.2.2"},
      {:poison, "~> 6.0.0"}
    ]
  end
end
