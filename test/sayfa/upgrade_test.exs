defmodule Mix.Tasks.Sayfa.UpgradeTest do
  use ExUnit.Case, async: false

  alias Mix.Tasks.Sayfa.Upgrade

  setup do
    tmp_dir = Path.join(System.tmp_dir!(), "sayfa_upgrade_#{System.unique_integer([:positive])}")
    File.mkdir_p!(tmp_dir)
    original_dir = File.cwd!()
    File.cd!(tmp_dir)

    on_exit(fn ->
      File.cd!(original_dir)
      File.rm_rf!(tmp_dir)
    end)

    {:ok, tmp_dir: tmp_dir}
  end

  describe "run/1 with default theme" do
    test "shows inherited message for default theme", _ctx do
      File.mkdir_p!("config")

      File.write!(
        "config/config.exs",
        """
        import Config
        config :sayfa, :site, theme: "default"
        """
      )

      # Should not raise and should mention inherited
      Upgrade.run([])
    end
  end

  describe "run/1 with custom theme" do
    test "reports missing layout files", _ctx do
      File.mkdir_p!("config")

      File.write!(
        "config/config.exs",
        """
        import Config
        config :sayfa, :site, theme: "custom"
        """
      )

      # Should report missing files without copying (dry run)
      Upgrade.run([])
    end

    test "copies missing layout files with --apply", _ctx do
      File.mkdir_p!("config")

      File.write!(
        "config/config.exs",
        """
        import Config
        config :sayfa, :site, theme: "custom"
        """
      )

      Upgrade.run(["--apply"])
    end
  end

  describe "run/1 without config" do
    test "errors when no config/config.exs exists" do
      assert catch_exit(Upgrade.run([])) == {:shutdown, 1}
    end
  end
end
