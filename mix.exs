defmodule Sayfa.MixProject do
  use Mix.Project

  @version "0.2.0"
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
      {:tailwind, "~> 0.4", runtime: false},
      {:plug_cowboy, "~> 2.7"},
      {:file_system, "~> 1.0"},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end

  defp docs do
    [
      main: "Sayfa",
      homepage_url: @source_url,
      extras: [
        "README.md",
        "CHANGELOG.md",
        "CONTRIBUTING.md",
        "LICENSE"
      ],
      groups_for_modules: [
        Core: [Sayfa, Sayfa.Builder, Sayfa.Config, Sayfa.Content, Sayfa.Content.Raw],
        "Content Types": [
          Sayfa.ContentTypes.Post,
          Sayfa.ContentTypes.Note,
          Sayfa.ContentTypes.Project,
          Sayfa.ContentTypes.Talk,
          Sayfa.ContentTypes.Page
        ],
        "Templates & Blocks": [Sayfa.Template, Sayfa.Theme, Sayfa.Block],
        Blocks: [
          Sayfa.Blocks.Hero,
          Sayfa.Blocks.Header,
          Sayfa.Blocks.Footer,
          Sayfa.Blocks.SocialLinks,
          Sayfa.Blocks.Toc,
          Sayfa.Blocks.RecentPosts,
          Sayfa.Blocks.TagCloud,
          Sayfa.Blocks.ReadingTime,
          Sayfa.Blocks.CodeCopy
        ],
        Features: [
          Sayfa.Feed,
          Sayfa.Sitemap,
          Sayfa.SEO,
          Sayfa.Pagination,
          Sayfa.ReadingTime,
          Sayfa.Toc,
          Sayfa.I18n,
          Sayfa.Markdown
        ],
        Behaviours: [
          Sayfa.Behaviours.Block,
          Sayfa.Behaviours.Hook,
          Sayfa.Behaviours.ContentType
        ],
        "Dev Server": [
          Sayfa.DevServer.Supervisor,
          Sayfa.DevServer.Plug,
          Sayfa.DevServer.Watcher,
          Sayfa.DevServer.Rebuilder
        ]
      ]
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      files: ~w(lib priv .formatter.exs mix.exs README.md LICENSE CHANGELOG.md)
    ]
  end
end
