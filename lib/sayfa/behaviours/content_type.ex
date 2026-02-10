defmodule Sayfa.Behaviours.ContentType do
  @moduledoc """
  Behaviour for defining content types.

  Content types describe how a category of content is organized:
  which directory it lives in, its URL prefix, default layout, and
  which front matter fields are required.

  ## Examples

      defmodule MyApp.ContentTypes.Recipe do
        @behaviour Sayfa.Behaviours.ContentType

        @impl true
        def name, do: :recipe

        @impl true
        def directory, do: "recipes"

        @impl true
        def url_prefix, do: "recipes"

        @impl true
        def default_layout, do: "page"

        @impl true
        def required_fields, do: [:title]
      end

  """

  @doc "Atom identifier for this content type."
  @callback name() :: atom()

  @doc "Directory name under `content/` where files of this type live."
  @callback directory() :: String.t()

  @doc "URL path prefix. Empty string for top-level pages."
  @callback url_prefix() :: String.t()

  @doc "Default layout template name (without extension)."
  @callback default_layout() :: String.t()

  @doc "Front matter fields that must be present."
  @callback required_fields() :: [atom()]
end
