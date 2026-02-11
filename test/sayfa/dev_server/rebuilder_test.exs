defmodule Sayfa.DevServer.RebuilderTest do
  use ExUnit.Case, async: false

  alias Sayfa.DevServer.Rebuilder

  setup do
    tmp_dir = Path.join(System.tmp_dir!(), "sayfa_rebuilder_#{System.unique_integer([:positive])}")
    content_dir = Path.join(tmp_dir, "content")
    output_dir = Path.join(tmp_dir, "output")
    posts_dir = Path.join(content_dir, "posts")

    File.mkdir_p!(posts_dir)

    File.write!(Path.join(posts_dir, "hello.md"), """
    ---
    title: "Hello"
    ---
    Hello content.
    """)

    on_exit(fn ->
      if Process.whereis(Rebuilder), do: GenServer.stop(Rebuilder)
      File.rm_rf!(tmp_dir)
    end)

    {:ok, content_dir: content_dir, output_dir: output_dir, posts_dir: posts_dir}
  end

  test "initial build increments build_id to 1", ctx do
    {:ok, _pid} =
      Rebuilder.start_link(
        config: [content_dir: ctx.content_dir, output_dir: ctx.output_dir]
      )

    assert Rebuilder.build_id() == 1
  end

  test "trigger_rebuild increments build_id after debounce", ctx do
    {:ok, _pid} =
      Rebuilder.start_link(
        config: [content_dir: ctx.content_dir, output_dir: ctx.output_dir]
      )

    assert Rebuilder.build_id() == 1

    Rebuilder.trigger_rebuild("test change")
    # Wait for debounce (200ms) + build time
    Process.sleep(500)

    assert Rebuilder.build_id() == 2
  end

  test "rapid triggers are debounced into single rebuild", ctx do
    {:ok, _pid} =
      Rebuilder.start_link(
        config: [content_dir: ctx.content_dir, output_dir: ctx.output_dir]
      )

    assert Rebuilder.build_id() == 1

    # Trigger multiple times in quick succession
    Rebuilder.trigger_rebuild("change 1")
    Rebuilder.trigger_rebuild("change 2")
    Rebuilder.trigger_rebuild("change 3")

    # Wait for debounce + build
    Process.sleep(500)

    # Should have only rebuilt once (debounced)
    assert Rebuilder.build_id() == 2
  end
end
