defmodule Sayfa.DevServer.PlugTest do
  use ExUnit.Case, async: true
  import Plug.Test

  alias Sayfa.DevServer.Plug, as: DevPlug

  setup do
    tmp_dir = Path.join(System.tmp_dir!(), "sayfa_plug_test_#{System.unique_integer([:positive])}")
    File.mkdir_p!(tmp_dir)

    # Create test files
    File.write!(Path.join(tmp_dir, "index.html"), """
    <!DOCTYPE html><html><body><h1>Home</h1></body></html>
    """)

    File.mkdir_p!(Path.join(tmp_dir, "posts"))

    File.write!(Path.join([tmp_dir, "posts", "index.html"]), """
    <!DOCTYPE html><html><body><h1>Posts</h1></body></html>
    """)

    File.write!(Path.join(tmp_dir, "style.css"), "body { color: red; }")
    File.write!(Path.join(tmp_dir, "app.js"), "console.log('hello');")

    on_exit(fn -> File.rm_rf!(tmp_dir) end)

    {:ok, output_dir: tmp_dir}
  end

  defp call_plug(conn, output_dir) do
    opts = DevPlug.init(output_dir: output_dir)
    DevPlug.call(conn, opts)
  end

  describe "static file serving" do
    test "serves files from output directory", %{output_dir: dir} do
      conn = conn(:get, "/style.css") |> call_plug(dir)
      assert conn.status == 200
      assert conn.resp_body == "body { color: red; }"
      assert {"content-type", "text/css; charset=utf-8"} in conn.resp_headers
    end

    test "serves JavaScript files", %{output_dir: dir} do
      conn = conn(:get, "/app.js") |> call_plug(dir)
      assert conn.status == 200
      assert conn.resp_body == "console.log('hello');"
    end

    test "returns 404 for missing files", %{output_dir: dir} do
      conn = conn(:get, "/nonexistent.html") |> call_plug(dir)
      assert conn.status == 404
    end
  end

  describe "index.html resolution" do
    test "serves index.html for root path", %{output_dir: dir} do
      conn = conn(:get, "/") |> call_plug(dir)
      assert conn.status == 200
      assert conn.resp_body =~ "Home"
    end

    test "serves index.html for directory paths", %{output_dir: dir} do
      conn = conn(:get, "/posts") |> call_plug(dir)
      assert conn.status == 200
      assert conn.resp_body =~ "Posts"
    end

    test "returns 404 for directory without index.html", %{output_dir: dir} do
      File.mkdir_p!(Path.join(dir, "empty"))
      conn = conn(:get, "/empty") |> call_plug(dir)
      assert conn.status == 404
    end
  end

  describe "live reload injection" do
    test "injects script into HTML responses", %{output_dir: dir} do
      conn = conn(:get, "/") |> call_plug(dir)
      assert conn.resp_body =~ "/__sayfa/build_id"
      assert conn.resp_body =~ "<script>"
    end

    test "does not inject script into non-HTML responses", %{output_dir: dir} do
      conn = conn(:get, "/style.css") |> call_plug(dir)
      refute conn.resp_body =~ "/__sayfa/build_id"
    end
  end

  describe "build_id endpoint" do
    test "returns build_id as text", %{output_dir: dir} do
      conn = conn(:get, "/__sayfa/build_id") |> call_plug(dir)
      assert conn.status == 200
      assert {"content-type", "text/plain; charset=utf-8"} in conn.resp_headers
      # Rebuilder not running, so returns "0"
      assert conn.resp_body == "0"
    end
  end

  describe "inject_live_reload/1" do
    test "inserts script before </body>" do
      html = "<html><body><h1>Hello</h1></body></html>"
      result = DevPlug.inject_live_reload(html)
      assert result =~ "/__sayfa/build_id"
      assert result =~ "</body></html>"
    end

    test "appends script when no </body> tag" do
      html = "<h1>Hello</h1>"
      result = DevPlug.inject_live_reload(html)
      assert result =~ "/__sayfa/build_id"
    end
  end
end
