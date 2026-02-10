defmodule Sayfa.ContentTypes.Talk do
  @moduledoc """
  Content type for conference talks and presentations.

  Talks live in `content/talks/` and are rendered at `/talks/{slug}/`.
  """

  @behaviour Sayfa.Behaviours.ContentType

  @impl true
  def name, do: :talk

  @impl true
  def directory, do: "talks"

  @impl true
  def url_prefix, do: "talks"

  @impl true
  def default_layout, do: "page"

  @impl true
  def required_fields, do: [:title]
end
