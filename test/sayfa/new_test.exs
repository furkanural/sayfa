defmodule Mix.Tasks.Sayfa.NewTest do
  use ExUnit.Case, async: false

  alias Mix.Tasks.Sayfa.New

  setup do
    tmp_dir = Path.join(System.tmp_dir!(), "sayfa_new_#{System.unique_integer([:positive])}")
    on_exit(fn -> File.rm_rf!(tmp_dir) end)
    {:ok, tmp_dir: tmp_dir}
  end

  describe "run/1" do
    test "creates a new project with default options", ctx do
      project_path = Path.join(ctx.tmp_dir, "my_blog")

      New.run([project_path])

      # Verify directory structure
      assert File.dir?(project_path)
      assert File.dir?(Path.join(project_path, "config"))
      assert File.dir?(Path.join(project_path, "content/posts"))
      assert File.dir?(Path.join(project_path, "content/pages"))

      # Verify generated files
      assert File.exists?(Path.join(project_path, "mix.exs"))
      assert File.exists?(Path.join(project_path, "config/config.exs"))
      assert File.exists?(Path.join(project_path, "content/posts/welcome.md"))
      assert File.exists?(Path.join(project_path, "content/pages/about.md"))
      assert File.exists?(Path.join(project_path, ".formatter.exs"))
      assert File.exists?(Path.join(project_path, ".gitignore"))

      # Verify content
      mix_exs = File.read!(Path.join(project_path, "mix.exs"))
      assert mix_exs =~ "MyBlog.MixProject"
      assert mix_exs =~ ":my_blog"
      assert mix_exs =~ "{:sayfa"

      config = File.read!(Path.join(project_path, "config/config.exs"))
      assert config =~ "My Blog"
      assert config =~ "default_lang: :en"

      welcome = File.read!(Path.join(project_path, "content/posts/welcome.md"))
      assert welcome =~ "Welcome to My Blog"
      assert welcome =~ "tags: [welcome]"

      about = File.read!(Path.join(project_path, "content/pages/about.md"))
      assert about =~ "About My Blog"

      # Verify index.md (home page)
      index = File.read!(Path.join(project_path, "content/pages/index.md"))
      assert index =~ "layout: home"
      assert index =~ "Welcome to"

      # Verify README
      readme = File.read!(Path.join(project_path, "README.md"))
      assert readme =~ "My Blog"
      assert readme =~ "## Deployment"

      # Verify nixpacks.toml
      assert File.exists?(Path.join(project_path, "nixpacks.toml"))
      nixpacks = File.read!(Path.join(project_path, "nixpacks.toml"))
      assert nixpacks =~ "elixir_1_19"
      assert nixpacks =~ "rustc"
      assert nixpacks =~ "mix sayfa.build"

      # Verify GitHub Actions deploy workflow
      assert File.exists?(Path.join(project_path, ".github/workflows/deploy.yml"))
      deploy_yml = File.read!(Path.join(project_path, ".github/workflows/deploy.yml"))
      assert deploy_yml =~ "Deploy to GitHub Pages"

      # Verify .gitignore has descriptive comment
      gitignore = File.read!(Path.join(project_path, ".gitignore"))
      assert gitignore =~ "Build artifact"

      # Verify git init (if git is available)
      if System.find_executable("git") do
        assert File.dir?(Path.join(project_path, ".git"))
      end
    end

    test "creates project with custom title", ctx do
      project_path = Path.join(ctx.tmp_dir, "cool_site")

      New.run([project_path, "--title", "Cool Site"])

      config = File.read!(Path.join(project_path, "config/config.exs"))
      assert config =~ "Cool Site"

      welcome = File.read!(Path.join(project_path, "content/posts/welcome.md"))
      assert welcome =~ "Welcome to Cool Site"
    end

    test "creates project with multiple languages", ctx do
      project_path = Path.join(ctx.tmp_dir, "multi_lang")

      New.run([project_path, "--lang", "en,tr"])

      config = File.read!(Path.join(project_path, "config/config.exs"))
      assert config =~ "default_lang: :en"
      assert config =~ "tr:"

      # Turkish content directory created
      assert File.dir?(Path.join([project_path, "content", "tr", "posts"]))
    end

    test "errors when directory already exists", ctx do
      project_path = Path.join(ctx.tmp_dir, "existing")
      File.mkdir_p!(project_path)

      assert catch_exit(New.run([project_path]))
    end

    test "errors when no path given" do
      assert catch_exit(New.run([]))
    end
  end
end
