defmodule Mix.Tasks.Sayfa.Gen.Block do
  @moduledoc """
  Generates a custom block module scaffold.

  ## Usage

      mix sayfa.gen.block ModuleName

  ## Examples

      mix sayfa.gen.block MyBanner
      mix sayfa.gen.block MyApp.Blocks.Hero

  The last segment of the module name is used to derive the block name and file name.
  For example, `MyApp.Blocks.Hero` produces `lib/blocks/hero.ex` with block name `:hero`.

  ## After generation

  Register your block in `config/config.exs`:

      config :sayfa, :blocks, [MyApp.Blocks.MyBanner | Sayfa.Block.default_blocks()]
  """

  use Mix.Task

  @shortdoc "Scaffold a custom block module"

  @impl Mix.Task
  def run([module_name | _]) do
    last_segment = module_name |> String.split(".") |> List.last()
    block_name = to_snake_case(last_segment)
    file_path = Path.join(["lib", "blocks", "#{block_name}.ex"])

    if File.exists?(file_path) do
      Mix.shell().error("File already exists: #{file_path}")
      exit({:shutdown, 1})
    end

    template_path =
      Path.join([to_string(:code.priv_dir(:sayfa)), "templates", "gen_block", "block.ex.eex"])

    content =
      EEx.eval_file(template_path,
        assigns: [module_name: module_name, block_name: block_name]
      )

    File.mkdir_p!(Path.dirname(file_path))
    File.write!(file_path, content)

    Mix.shell().info("#{IO.ANSI.green()}Created#{IO.ANSI.reset()} #{file_path}")
    Mix.shell().info("")
    Mix.shell().info("Register your block in config/config.exs:")
    Mix.shell().info("")

    Mix.shell().info(
      "    config :sayfa, :blocks, [#{module_name} | Sayfa.Block.default_blocks()]"
    )
  end

  def run([]) do
    Mix.shell().error("Usage: mix sayfa.gen.block ModuleName")
    exit({:shutdown, 1})
  end

  defp to_snake_case(name) do
    name
    |> String.replace(~r/([A-Z]+)([A-Z][a-z])/, "\\1_\\2")
    |> String.replace(~r/([a-z\d])([A-Z])/, "\\1_\\2")
    |> String.downcase()
  end
end
