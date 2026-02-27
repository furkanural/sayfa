defmodule Sayfa.Tailwind do
  @moduledoc """
  TailwindCSS integration for compiling theme styles.

  Uses the `tailwind` hex package to automatically download and run the
  TailwindCSS CLI. The correct platform-specific binary is downloaded and
  cached on first use — no manual installation required.

  The input CSS is resolved through the theme chain — custom theme CSS takes
  priority, falling back to the default theme's `assets/css/main.css`.

  ## Examples

      config = Sayfa.Config.resolve()
      Sayfa.Tailwind.compile(config, "dist")

  """

  require Logger

  @profile :sayfa

  @doc """
  Compiles TailwindCSS for the site.

  Finds the input CSS through the theme chain, then runs the `tailwindcss` CLI
  (auto-downloading on first use) to produce a minified CSS file at
  `<output_dir>/assets/css/main.css`.

  Returns `:ok` on success, or `:skipped` if no input CSS is found in the
  theme chain.

  ## Options

  - `:minify` — whether to minify the output (default: `true`)

  ## Examples

      Sayfa.Tailwind.compile(config, "dist")
      #=> :ok

      Sayfa.Tailwind.compile(config, "dist", minify: false)
      #=> :ok

  """
  @spec compile(map(), String.t(), keyword()) :: :ok | :skipped
  def compile(config, output_dir, opts \\ []) do
    case resolve_input_css(config) do
      nil ->
        Logger.info("No input CSS found in theme chain, skipping Tailwind compilation")
        :skipped

      input_path ->
        output_path = Path.join([output_dir, "assets", "css", "main.css"])
        File.mkdir_p!(Path.dirname(output_path))

        minify = Keyword.get(opts, :minify, true)

        args =
          ["-i", input_path, "-o", output_path] ++
            if(minify, do: ["--minify"], else: [])

        version = Map.get(config, :tailwind_version, "4.1.12")
        configure(version, args)

        case Tailwind.install_and_run(@profile, []) do
          0 ->
            Logger.info("TailwindCSS compilation complete")
            :ok

          code ->
            Logger.warning("TailwindCSS compilation failed (exit #{code})")
            :ok
        end
    end
  end

  @doc """
  Resolves the input CSS file path through the theme chain.

  Walks from custom theme → parent theme → default theme, returning
  the first `assets/css/main.css` that exists.

  Returns `nil` if no input CSS is found.

  ## Examples

      iex> config = %{theme: "default", theme_parent: "default"}
      iex> path = Sayfa.Tailwind.resolve_input_css(config)
      iex> is_binary(path) or is_nil(path)
      true

  """
  @spec resolve_input_css(map()) :: String.t() | nil
  def resolve_input_css(config) do
    theme = Map.get(config, :theme, "default")
    parent = Map.get(config, :theme_parent, "default")

    candidates =
      [theme, parent, "default"]
      |> Enum.uniq()
      |> Enum.map(&css_path_for/1)

    Enum.find(candidates, &File.exists?/1)
  end

  # --- Private ---

  defp configure(version, args) do
    Application.put_env(:tailwind, :version, version)

    Application.put_env(:tailwind, @profile,
      args: args,
      cd: File.cwd!()
    )
  end

  defp css_path_for("default") do
    Sayfa.Config.default_theme_path(Path.join(["assets", "css", "main.css"]))
  end

  defp css_path_for(theme_name) do
    Path.join(["themes", theme_name, "assets", "css", "main.css"])
  end
end
