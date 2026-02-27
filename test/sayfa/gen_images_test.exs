defmodule Mix.Tasks.Sayfa.Gen.ImagesTest do
  use ExUnit.Case, async: false

  alias Mix.Tasks.Sayfa.Gen.Images

  setup do
    tmp_dir =
      Path.join(System.tmp_dir!(), "sayfa_gen_images_#{System.unique_integer([:positive])}")

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
    test "creates optimize_images.sh in scripts/", ctx do
      Images.run([])

      dest = Path.join([ctx.tmp_dir, "scripts", "optimize_images.sh"])
      assert File.exists?(dest)
    end

    test "creates IMAGES.md", ctx do
      Images.run([])

      dest = Path.join([ctx.tmp_dir, "IMAGES.md"])
      assert File.exists?(dest)
    end

    test "optimize_images.sh contains vips usage" do
      Images.run([])

      content = File.read!("scripts/optimize_images.sh")
      assert content =~ "vips"
    end

    test "IMAGES.md contains documentation" do
      Images.run([])

      content = File.read!("IMAGES.md")
      assert content =~ "vips"
      assert content =~ "ImageMagick"
    end

    test "errors when optimize_images.sh already exists", ctx do
      dest_dir = Path.join(ctx.tmp_dir, "scripts")
      File.mkdir_p!(dest_dir)
      File.write!(Path.join(dest_dir, "optimize_images.sh"), "existing")

      assert catch_exit(Images.run([]))
    end

    test "errors when IMAGES.md already exists", _ctx do
      # Run once to create both files
      Images.run([])
      # Reset to fresh tmp dir approach: manually create IMAGES.md
      File.rm!("scripts/optimize_images.sh")

      assert catch_exit(Images.run([]))
    end
  end
end
