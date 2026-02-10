defmodule Sayfa.ContentTypes.Page do
  @moduledoc """
  Content type for standalone pages.

  Pages live in `content/pages/` and are rendered at `/{slug}/` (no prefix).
  """

  @behaviour Sayfa.Behaviours.ContentType

  @impl true
  def name, do: :page

  @impl true
  def directory, do: "pages"

  @impl true
  def url_prefix, do: ""

  @impl true
  def default_layout, do: "page"

  @impl true
  def required_fields, do: [:title]
end
