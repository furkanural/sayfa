defmodule Mix.Tasks.Sayfa.CleanTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Mix.Tasks.Sayfa.Clean

  setup do
    tmp_dir = Path.join(System.tmp_dir!(), "sayfa_clean_test_#{:rand.uniform(999_999)}")
    File.mkdir_p!(tmp_dir)

    on_exit(fn ->
      File.rm_rf!(tmp_dir)
    end)

    {:ok, tmp_dir: tmp_dir}
  end

  describe "run/1" do
    test "removes the default output directory", %{tmp_dir: tmp_dir} do
      output_dir = Path.join(tmp_dir, "dist")
      File.mkdir_p!(output_dir)
      File.write!(Path.join(output_dir, "index.html"), "test")

      File.cd!(tmp_dir, fn ->
        output =
          capture_io(fn ->
            Clean.run([])
          end)

        assert output =~ "Cleaned dist"
        refute File.exists?(output_dir)
      end)
    end

    test "removes a custom output directory", %{tmp_dir: tmp_dir} do
      output_dir = Path.join(tmp_dir, "build")
      File.mkdir_p!(output_dir)
      File.write!(Path.join(output_dir, "index.html"), "test")

      File.cd!(tmp_dir, fn ->
        output =
          capture_io(fn ->
            Clean.run(["--output", "build"])
          end)

        assert output =~ "Cleaned build"
        refute File.exists?(output_dir)
      end)
    end
  end
end
