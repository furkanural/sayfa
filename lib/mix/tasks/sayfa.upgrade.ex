defmodule Mix.Tasks.Sayfa.Upgrade do
  @moduledoc """
  Upgrade your Sayfa site by syncing new theme files from the package.

  Compares your project's theme against the built-in default theme and reports
  missing files (e.g. new layouts like 404.html.eex). In dry-run mode nothing
  is copied.

  ## Usage

      mix sayfa.upgrade              # Dry run — show what would change
      mix sayfa.upgrade --apply      # Copy missing files
      mix sayfa.upgrade --force      # Overwrite existing files too
      mix sayfa.upgrade --theme NAME # Target a specific theme (default: read from config)

  ## Examples

      mix sayfa.upgrade --apply
      mix sayfa.upgrade --theme custom --apply

  """

  use Mix.Task

  @shortdoc "Sync new theme files from Sayfa into your project"

  @switches [
    apply: :boolean,
    force: :boolean,
    theme: :string
  ]

  @impl Mix.Task
  def run(args) do
    {opts, _argv, _} = OptionParser.parse(args, switches: @switches)

    apply? = Keyword.get(opts, :apply, false)
    force? = Keyword.get(opts, :force, false)
    theme = opts[:theme]

    config_path = "config/config.exs"

    unless File.exists?(config_path) do
      Mix.shell().error("No config/config.exs found. Are you inside a Sayfa project?")
      exit({:shutdown, 1})
    end

    theme = theme || read_theme(config_path)

    source_layouts_dir = default_theme_path("layouts")
    source_assets_dir = default_theme_path("assets")

    if theme == "default" do
      Mix.shell().info(
        "Using #{IO.ANSI.cyan()}default#{IO.ANSI.reset()} theme — layouts and assets are inherited automatically."
      )

      Mix.shell().info("")
      list_new_defaults(source_layouts_dir, "layouts")
      Mix.shell().info("")
      list_new_defaults(source_assets_dir, "assets")

      Mix.shell().info("")

      Mix.shell().info(
        "Run #{IO.ANSI.cyan()}mix sayfa.gen.layout <name>#{IO.ANSI.reset()} to customize a layout,"
      )

      Mix.shell().info(
        "or #{IO.ANSI.cyan()}mix sayfa.upgrade --theme custom --apply#{IO.ANSI.reset()} to set up a custom theme."
      )
    else
      upgrade_theme(theme, source_layouts_dir, source_assets_dir, apply?, force?)
    end
  end

  defp upgrade_theme(theme, source_layouts_dir, source_assets_dir, apply?, force?) do
    dest_layouts_dir = Path.join(["themes", theme, "layouts"])
    dest_assets_dir = Path.join(["themes", theme, "assets"])

    {layout_changes, layout_counts} =
      compare_and_sync(source_layouts_dir, dest_layouts_dir, apply?, force?)

    {asset_changes, asset_counts} =
      compare_and_sync(source_assets_dir, dest_assets_dir, apply?, force?)

    if layout_changes == [] and asset_changes == [] do
      Mix.shell().info(IO.ANSI.green() <> "Your theme is up to date!" <> IO.ANSI.reset())
    else
      print_report(layout_changes, "Layouts", layout_counts)
      print_report(asset_changes, "Assets", asset_counts)

      Mix.shell().info("")

      print_upgrade_result(layout_counts, asset_counts, apply?)
    end
  end

  defp compare_and_sync(source_dir, dest_dir, apply?, force?) do
    source_files = list_files(source_dir)
    dest_files = list_files(dest_dir)

    missing = source_files -- dest_files
    common = if force?, do: dest_files -- (dest_files -- source_files), else: []

    overwritten =
      common
      |> Enum.filter(fn rel ->
        src = Path.join(source_dir, rel)
        dst = Path.join(dest_dir, rel)
        File.read!(src) != File.read!(dst)
      end)
      |> Enum.map(fn rel ->
        {:overwrite, rel, Path.join(source_dir, rel), Path.join(dest_dir, rel)}
      end)

    created =
      Enum.map(missing, fn rel ->
        {:create, rel, Path.join(source_dir, rel), Path.join(dest_dir, rel)}
      end)

    changes = created ++ overwritten

    if apply? do
      Enum.each(changes, fn
        {:create, _rel, src, dst} ->
          File.mkdir_p!(Path.dirname(dst))
          File.cp!(src, dst)

        {:overwrite, _rel, src, dst} ->
          File.cp!(src, dst)
      end)
    end

    created_count = Enum.count(changes, fn {action, _, _, _} -> action == :create end)
    overwritten_count = Enum.count(changes, fn {action, _, _, _} -> action == :overwrite end)

    {changes, {created_count, overwritten_count}}
  end

  defp list_files(dir) do
    if File.dir?(dir) do
      dir
      |> Path.join("**/*")
      |> Path.wildcard()
      |> Enum.reject(&File.dir?/1)
      |> Enum.map(&Path.relative_to(&1, dir))
      |> Enum.sort()
    else
      []
    end
  end

  defp print_report([], _label, _counts), do: :ok

  defp print_report(changes, label, {created, overwritten}) do
    Mix.shell().info("")
    Mix.shell().info("#{label}:")

    Enum.each(changes, fn
      {:create, rel, _src, _dst} ->
        Mix.shell().info("  #{IO.ANSI.green()}create#{IO.ANSI.reset()}  #{rel}")

      {:overwrite, rel, _src, _dst} ->
        Mix.shell().info("  #{IO.ANSI.yellow()}overwrite#{IO.ANSI.reset()} #{rel}")
    end)

    if created > 0 do
      Mix.shell().info("  #{created} new file(s)")
    end

    if overwritten > 0 do
      Mix.shell().info("  #{overwritten} changed file(s)")
    end
  end

  defp print_upgrade_result(layout_counts, asset_counts, true = _apply?) do
    {created, overwritten} = layout_counts
    {a_created, a_overwritten} = asset_counts
    total = created + overwritten + a_created + a_overwritten
    overwritten_total = overwritten + a_overwritten

    suffix = if overwritten_total > 0, do: " (#{overwritten_total} overwritten)", else: ""

    Mix.shell().info(IO.ANSI.green() <> "Upgraded #{total} file(s)#{suffix}." <> IO.ANSI.reset())
  end

  defp print_upgrade_result(_layout_counts, _asset_counts, false = _apply?) do
    Mix.shell().info("Run with #{IO.ANSI.cyan()}--apply#{IO.ANSI.reset()} to copy these files.")
  end

  defp list_new_defaults(source_dir, label) do
    files = list_files(source_dir)

    if files != [] do
      Mix.shell().info("Available #{label} in default theme:")
      Enum.each(files, fn f -> Mix.shell().info("  #{f}") end)
    end
  end

  defp read_theme(config_path) do
    config = Config.Reader.read!(config_path)
    site_config = get_in(config, [:sayfa, :site]) || []
    Keyword.get(site_config, :theme, "default")
  rescue
    _ -> "default"
  end

  defp default_theme_path(subpath) do
    case :code.priv_dir(:sayfa) do
      {:error, :bad_name} ->
        Path.join([File.cwd!(), "priv", "default_theme", subpath])

      dir ->
        Path.join([List.to_string(dir), "default_theme", subpath])
    end
  end
end
