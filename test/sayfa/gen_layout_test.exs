defmodule Mix.Tasks.Sayfa.Gen.LayoutTest do
  use ExUnit.Case, async: false

  alias Mix.Tasks.Sayfa.Gen.Layout

  setup do
    # Work in a temp directory so layout files are written there
    tmp_dir =
      Path.join(System.tmp_dir!(), "sayfa_gen_layout_#{System.unique_integer([:positive])}")

    File.mkdir_p!(tmp_dir)
    original_dir = File.cwd!()
    File.cd!(tmp_dir)

    on_exit(fn ->
      File.cd!(original_dir)
      File.rm_rf!(tmp_dir)
    end)

    {:ok, tmp_dir: tmp_dir}
  end

  describe "run/1" do
    test "copies layout file to themes/custom/layouts/", ctx do
      Layout.run(["post"])

      dest = Path.join([ctx.tmp_dir, "themes", "custom", "layouts", "post.html.eex"])
      assert File.exists?(dest)

      content = File.read!(dest)
      assert content =~ "inner_content"
    end

    test "errors for unknown layout name" do
      assert catch_exit(Layout.run(["nonexistent_layout"]))
    end

    test "errors when no name given" do
      assert catch_exit(Layout.run([]))
    end

    test "errors when file already exists", ctx do
      dest_dir = Path.join([ctx.tmp_dir, "themes", "custom", "layouts"])
      File.mkdir_p!(dest_dir)
      File.write!(Path.join(dest_dir, "post.html.eex"), "existing")

      assert catch_exit(Layout.run(["post"]))
    end

    test "--list shows available layouts" do
      # Should not raise
      Layout.run(["--list"])
    end
  end
end
