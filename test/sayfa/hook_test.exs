defmodule Sayfa.HookTest do
  use ExUnit.Case, async: false

  alias Sayfa.Builder
  alias Sayfa.Content

  # --- Test Hook Modules ---

  defmodule UppercaseTitleHook do
    @behaviour Sayfa.Behaviours.Hook

    @impl true
    def stage, do: :after_parse

    @impl true
    def run(%Content{} = content, _opts) do
      {:ok, %{content | title: String.upcase(content.title)}}
    end
  end

  defmodule BeforeParseHook do
    @behaviour Sayfa.Behaviours.Hook

    @impl true
    def stage, do: :before_parse

    @impl true
    def run(%Content.Raw{} = raw, _opts) do
      updated_body = raw.body_markdown <> "\n\nInjected by hook."
      {:ok, %{raw | body_markdown: updated_body}}
    end
  end

  defmodule BeforeRenderHook do
    @behaviour Sayfa.Behaviours.Hook

    @impl true
    def stage, do: :before_render

    @impl true
    def run(%Content{} = content, _opts) do
      meta = Map.put(content.meta, "hook_ran", true)
      {:ok, %{content | meta: meta}}
    end
  end

  defmodule AfterRenderHook do
    @behaviour Sayfa.Behaviours.Hook

    @impl true
    def stage, do: :after_render

    @impl true
    def run({content, html}, _opts) do
      {:ok, {content, html <> "<!-- hook -->"}}
    end
  end

  defmodule ErrorHook do
    @behaviour Sayfa.Behaviours.Hook

    @impl true
    def stage, do: :after_parse

    @impl true
    def run(_content, _opts) do
      {:error, :hook_failed}
    end
  end

  setup do
    tmp_dir = Path.join(System.tmp_dir!(), "sayfa_hook_#{System.unique_integer([:positive])}")
    content_dir = Path.join(tmp_dir, "content")
    output_dir = Path.join(tmp_dir, "output")
    posts_dir = Path.join(content_dir, "posts")

    File.mkdir_p!(posts_dir)

    on_exit(fn ->
      File.rm_rf!(tmp_dir)
      Application.delete_env(:sayfa, :hooks)
    end)

    {:ok, tmp_dir: tmp_dir, content_dir: content_dir, output_dir: output_dir, posts_dir: posts_dir}
  end

  describe "after_parse hook" do
    test "transforms content title", ctx do
      Application.put_env(:sayfa, :hooks, [UppercaseTitleHook])

      File.write!(Path.join(ctx.posts_dir, "test.md"), """
      ---
      title: "hello world"
      date: 2024-01-15
      ---
      Content here.
      """)

      assert {:ok, result} = Builder.build(content_dir: ctx.content_dir, output_dir: ctx.output_dir)
      assert result.content_count == 1

      html = File.read!(Path.join([ctx.output_dir, "posts", "test", "index.html"]))
      assert html =~ "HELLO WORLD"
    end
  end

  describe "before_parse hook" do
    test "modifies raw markdown", ctx do
      Application.put_env(:sayfa, :hooks, [BeforeParseHook])

      File.write!(Path.join(ctx.posts_dir, "test.md"), """
      ---
      title: "Test"
      date: 2024-01-15
      ---
      Original content.
      """)

      assert {:ok, _result} = Builder.build(content_dir: ctx.content_dir, output_dir: ctx.output_dir)

      html = File.read!(Path.join([ctx.output_dir, "posts", "test", "index.html"]))
      assert html =~ "Injected by hook"
    end
  end

  describe "after_render hook" do
    test "appends to rendered HTML", ctx do
      Application.put_env(:sayfa, :hooks, [AfterRenderHook])

      File.write!(Path.join(ctx.posts_dir, "test.md"), """
      ---
      title: "Test"
      date: 2024-01-15
      ---
      Content.
      """)

      assert {:ok, _result} = Builder.build(content_dir: ctx.content_dir, output_dir: ctx.output_dir)

      html = File.read!(Path.join([ctx.output_dir, "posts", "test", "index.html"]))
      assert html =~ "<!-- hook -->"
    end
  end

  describe "error handling" do
    test "error hook halts build", ctx do
      Application.put_env(:sayfa, :hooks, [ErrorHook])

      File.write!(Path.join(ctx.posts_dir, "test.md"), """
      ---
      title: "Test"
      ---
      Content.
      """)

      assert {:error, {:parse_error, _, :hook_failed}} =
               Builder.build(content_dir: ctx.content_dir, output_dir: ctx.output_dir)
    end
  end

  describe "multiple hooks" do
    test "hooks run in sequence", ctx do
      Application.put_env(:sayfa, :hooks, [BeforeParseHook, UppercaseTitleHook])

      File.write!(Path.join(ctx.posts_dir, "test.md"), """
      ---
      title: "hello"
      date: 2024-01-15
      ---
      Content.
      """)

      assert {:ok, _result} = Builder.build(content_dir: ctx.content_dir, output_dir: ctx.output_dir)

      html = File.read!(Path.join([ctx.output_dir, "posts", "test", "index.html"]))
      assert html =~ "HELLO"
      assert html =~ "Injected by hook"
    end
  end
end
