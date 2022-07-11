defmodule Amps.Kafka.MixProject do
  use Mix.Project

  def project do
    [
      app: :amps_kafka,
      config_path: "config/config.exs",
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:kafka_ex, git: "https://github.com/aram0112/kafka_ex"},
      {:jason, "~> 1.2"},
      {:snappyer, "~> 1.2"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
