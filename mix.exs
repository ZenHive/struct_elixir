defmodule Struct.MixProject do
  use Mix.Project

  def project do
    [
      app: :struct,
      version: "0.2.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: [
        flags: [
          :unmatched_returns,
          :missing_return
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
      {:ex_doc, "~> 0.37.3", only: :dev, runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:result, git: "git@github.com:ZenHive/result_elixir.git", tag: "v0.4.0"},
      {:option, git: "git@github.com:ZenHive/option_elixir.git", tag: "v0.1.0"}
    ]
  end
end
