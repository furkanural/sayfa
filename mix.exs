defmodule Sayfa.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/furkanural/sayfa"

  def project do
    [
      app: :sayfa,
      version: @version,
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "Sayfa",
      description: "A simple, extensible static site generator built in Elixir",
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
      {:mdex, "~> 0.2"},
      {:yaml_elixir, "~> 2.9"},
      {:slugify, "~> 1.3"},
      {:xml_builder, "~> 2.2"},
      {:plug_cowboy, "~> 2.7", optional: true},
      {:file_system, "~> 1.0", optional: true},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end

  defp docs do
    [
      main: "Sayfa",
      extras: ["README.md"]
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end
end
