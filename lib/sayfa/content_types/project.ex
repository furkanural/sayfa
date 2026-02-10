defmodule Sayfa.ContentTypes.Project do
  @moduledoc """
  Content type for project showcases.

  Projects live in `content/projects/` and are rendered at `/projects/{slug}/`.
  """

  @behaviour Sayfa.Behaviours.ContentType

  @impl true
  def name, do: :project

  @impl true
  def directory, do: "projects"

  @impl true
  def url_prefix, do: "projects"

  @impl true
  def default_layout, do: "page"

  @impl true
  def required_fields, do: [:title]
end
