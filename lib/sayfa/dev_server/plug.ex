defmodule Sayfa.DevServer.Plug do
  @moduledoc """
  HTTP server plug for the Sayfa dev server.

  Serves static files from the output directory, injects a live-reload
  polling script into HTML responses, and exposes `/__sayfa/build_id`
  for the reload mechanism.
  """

  use Plug.Router

  plug(:match)
  plug(:dispatch)

  @live_reload_script """
  <script>
  (function() {
    var lastId = null;
    setInterval(function() {
      fetch('/__sayfa/build_id')
        .then(function(r) { return r.text(); })
        .then(function(id) {
          if (lastId === null) { lastId = id; }
          else if (id !== lastId) { location.reload(); }
        })
        .catch(function() {});
    }, 1000);
  })();
  </script>
  """

  get "/__sayfa/build_id" do
    build_id =
      case Process.whereis(Sayfa.DevServer.Rebuilder) do
        nil -> "0"
        _pid -> "#{Sayfa.DevServer.Rebuilder.build_id()}"
      end

    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, build_id)
  end

  match _ do
    output_dir = conn.private[:output_dir] || "output"
    serve_static(conn, output_dir)
  end

  @doc false
  def init(opts), do: opts

  @doc false
  def call(conn, opts) do
    output_dir = Keyword.get(opts, :output_dir, "output")

    conn
    |> Plug.Conn.put_private(:output_dir, output_dir)
    |> super(opts)
  end

  defp serve_static(conn, output_dir) do
    path = Path.join([output_dir | conn.path_info])

    cond do
      File.regular?(path) ->
        serve_file(conn, path)

      File.dir?(path) ->
        index = Path.join(path, "index.html")

        if File.regular?(index) do
          serve_file(conn, index)
        else
          send_resp(conn, 404, "Not Found")
        end

      true ->
        send_resp(conn, 404, "Not Found")
    end
  end

  defp serve_file(conn, path) do
    content_type = MIME.from_path(path)
    body = File.read!(path)

    body =
      if String.starts_with?(content_type, "text/html") do
        inject_live_reload(body)
      else
        body
      end

    conn
    |> put_resp_content_type(content_type)
    |> send_resp(200, body)
  end

  @doc false
  def inject_live_reload(html) do
    if String.contains?(html, "</body>") do
      String.replace(html, "</body>", @live_reload_script <> "</body>")
    else
      html <> @live_reload_script
    end
  end
end
