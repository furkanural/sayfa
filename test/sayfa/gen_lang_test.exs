defmodule Mix.Tasks.Sayfa.Gen.LangTest do
  use ExUnit.Case, async: false

  alias Mix.Tasks.Sayfa.Gen.Lang

  @config_content """
  import Config
  config :sayfa, :site,
    title: "My Blog",
    default_lang: :en,
    languages: [en: [name: "English"]]
  """

  setup do
    tmp_dir =
      Path.join(System.tmp_dir!(), "sayfa_gen_lang_#{System.unique_integer([:positive])}")

    File.mkdir_p!(Path.join(tmp_dir, "config"))
    original_dir = File.cwd!()
    File.cd!(tmp_dir)

    File.write!(Path.join(tmp_dir, "config/config.exs"), @config_content)

    on_exit(fn ->
      File.cd!(original_dir)
      File.rm_rf!(tmp_dir)
    end)

    {:ok, tmp_dir: tmp_dir}
  end

  describe "run/1" do
    test "creates content directories", ctx do
      Lang.run(["tr"])

      assert File.dir?(Path.join([ctx.tmp_dir, "content", "tr", "pages"]))
      assert File.dir?(Path.join([ctx.tmp_dir, "content", "tr", "posts"]))
    end

    test "generates content files for known language", ctx do
      Lang.run(["tr"])

      index_path = Path.join([ctx.tmp_dir, "content", "tr", "pages", "index.md"])
      about_path = Path.join([ctx.tmp_dir, "content", "tr", "pages", "about.md"])
      post_path = Path.join([ctx.tmp_dir, "content", "tr", "posts", "building-with-sayfa.md"])

      assert File.exists?(index_path)
      assert File.exists?(about_path)
      assert File.exists?(post_path)

      index_content = File.read!(index_path)
      assert index_content =~ "lang: tr"
      assert index_content =~ "en: index"
    end

    test "generates content files for unknown language", ctx do
      Lang.run(["xx"])

      assert File.exists?(Path.join([ctx.tmp_dir, "content", "xx", "pages", "index.md"]))
      assert File.exists?(Path.join([ctx.tmp_dir, "content", "xx", "pages", "about.md"]))

      assert File.exists?(
               Path.join([ctx.tmp_dir, "content", "xx", "posts", "building-with-sayfa.md"])
             )
    end

    test "updates config with new language", ctx do
      Lang.run(["tr"])

      config_content = File.read!(Path.join(ctx.tmp_dir, "config/config.exs"))
      assert config_content =~ ~s(tr: [name: "Türkçe"])
    end

    test "skips config update if language already present", ctx do
      Lang.run(["tr"])
      Lang.run(["tr"])

      config_content = File.read!(Path.join(ctx.tmp_dir, "config/config.exs"))
      # Split produces n+1 parts for n occurrences; 2 parts = exactly 1 occurrence
      occurrences = config_content |> String.split(~s(tr: [name: "Türkçe"])) |> length()
      assert occurrences == 2
    end

    test "errors when no lang code given" do
      assert catch_exit(Lang.run([]))
    end

    test "errors when config does not exist", ctx do
      File.rm!(Path.join(ctx.tmp_dir, "config/config.exs"))
      assert catch_exit(Lang.run(["tr"]))
    end
  end
end
