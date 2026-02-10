defmodule Sayfa.ContentTypes.Post do
  @moduledoc """
  Content type for blog posts.

  Posts live in `content/posts/` and are rendered at `/posts/{slug}/`.
  They require a title and date in front matter.
  """

  @behaviour Sayfa.Behaviours.ContentType

  @impl true
  def name, do: :post

  @impl true
  def directory, do: "posts"

  @impl true
  def url_prefix, do: "posts"

  @impl true
  def default_layout, do: "post"

  @impl true
  def required_fields, do: [:title, :date]
end
