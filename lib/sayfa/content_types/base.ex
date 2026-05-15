defmodule Sayfa.ContentTypes.Base do
  @moduledoc """
  Base macro for content types.

  Reduces content type definitions from ~25 lines of boilerplate to ~3 lines.
  All five built-in types (article, note, page, project, talk) use this macro.

  ## Options

  - `:name` — atom identifier (required)
  - `:directory` — content subdirectory (default: `"<name>s"`)
  - `:url_prefix` — URL path prefix (default: directory)
  - `:layout` — default layout name (default: `to_string(name)`)
  - `:required_fields` — front matter requirements (default: `[:title, :date]`)

  ## Examples

      defmodule MyApp.ContentTypes.Recipe do
        use Sayfa.ContentTypes.Base, name: :recipe
      end

      defmodule MyApp.ContentTypes.Page do
        use Sayfa.ContentTypes.Base,
          name: :page,
          url_prefix: "",
          required_fields: [:title]
      end
  """

  defmacro __using__(opts) do
    name = Keyword.fetch!(opts, :name)
    directory = Keyword.get(opts, :directory, to_string(name) <> "s")
    url_prefix = Keyword.get(opts, :url_prefix, directory)
    layout = Keyword.get(opts, :layout, to_string(name))
    required_fields = Keyword.get(opts, :required_fields, [:title, :date])

    quote do
      @behaviour Sayfa.Behaviours.ContentType

      @impl true
      def name, do: unquote(name)

      @impl true
      def directory, do: unquote(directory)

      @impl true
      def url_prefix, do: unquote(url_prefix)

      @impl true
      def default_layout, do: unquote(layout)

      @impl true
      def required_fields, do: unquote(required_fields)
    end
  end
end
