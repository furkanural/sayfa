defmodule Sayfa.ContentTypes.Article do
  @moduledoc """
  Content type for articles.

  Articles live in `content/articles/` and are rendered at `/articles/{slug}/`.
  They require a title and date in front matter.
  """

  @behaviour Sayfa.Behaviours.ContentType

  @impl true
  def name, do: :article

  @impl true
  def directory, do: "articles"

  @impl true
  def url_prefix, do: "articles"

  @impl true
  def default_layout, do: "article"

  @impl true
  def required_fields, do: [:title, :date]
end
