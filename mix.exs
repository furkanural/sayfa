defmodule Sayfa.MixProject do
  use Mix.Project

  @version "0.5.0"
  @source_url "https://github.com/furkanural/sayfa"

  def project do
    [
      app: :sayfa,
      version: @version,
      elixir: "~> 1.19",
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
      {:mdex, "~> 0.12"},
      {:lumis, "~> 0.1"},
      {:yaml_elixir, "~> 2.12"},
      {:slugify, "~> 1.3"},
      {:xml_builder, "~> 2.4"},
      {:tailwind, "~> 0.4", runtime: false},
      {:plug_cowboy, "~> 2.8"},
      {:file_system, "~> 1.1"},
      {:ex_doc, "~> 0.40", only: :dev, runtime: false},
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
        Core: [
          Sayfa,
          Sayfa.Builder,
          Sayfa.Config,
          Sayfa.Content,
          Sayfa.Content.Raw,
          Sayfa.ContentType,
          Sayfa.Validator
        ],
        "Content Types": [
          Sayfa.ContentTypes.Article,
          Sayfa.ContentTypes.Note,
          Sayfa.ContentTypes.Page,
          Sayfa.ContentTypes.Project,
          Sayfa.ContentTypes.Talk,
          Sayfa.ContentTypes.Base
        ],
        "Templates & Blocks": [Sayfa.Template, Sayfa.Theme, Sayfa.Block],
        Blocks: [
          Sayfa.Blocks.Header,
          Sayfa.Blocks.Footer,
          Sayfa.Blocks.SocialLinks,
          Sayfa.Blocks.Toc,
          Sayfa.Blocks.TagCloud,
          Sayfa.Blocks.CategoryCloud,
          Sayfa.Blocks.ReadingTime,
          Sayfa.Blocks.CodeCopy,
          Sayfa.Blocks.RecentContent,
          Sayfa.Blocks.CopyLink,
          Sayfa.Blocks.Breadcrumb,
          Sayfa.Blocks.LanguageSwitcher,
          Sayfa.Blocks.RelatedContent,
          Sayfa.Blocks.Analytics,
          Sayfa.Blocks.Cloud,
          Sayfa.Blocks.Helpers
        ],
        Features: [
          Sayfa.Feed,
          Sayfa.Sitemap,
          Sayfa.SEO,
          Sayfa.Pagination,
          Sayfa.ReadingTime,
          Sayfa.Toc,
          Sayfa.I18n,
          Sayfa.Markdown,
          Sayfa.DateFormat,
          Sayfa.Excerpt,
          Sayfa.Image,
          Sayfa.Hooks.ResponsiveImages
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
        ],
        "Mix Tasks": [
          Mix.Tasks.Sayfa.New,
          Mix.Tasks.Sayfa.Build,
          Mix.Tasks.Sayfa.Serve,
          Mix.Tasks.Sayfa.Upgrade,
          Mix.Tasks.Sayfa.Clean,
          Mix.Tasks.Sayfa.Gen.Layout,
          Mix.Tasks.Sayfa.Gen.Content,
          Mix.Tasks.Sayfa.Gen.Lang,
          Mix.Tasks.Sayfa.Gen.Block,
          Mix.Tasks.Sayfa.Gen.ContentType,
          Mix.Tasks.Sayfa.Gen.Images
        ]
      ]
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      authors: ["Furkan Ural"],
      files: ~w(lib priv .formatter.exs mix.exs README.md LICENSE CHANGELOG.md CONTRIBUTING.md)
    ]
  end
end
