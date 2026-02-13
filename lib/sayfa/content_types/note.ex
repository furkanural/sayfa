defmodule Sayfa.ContentTypes.Note do
  @moduledoc """
  Content type for short notes.

  Notes live in `content/notes/` and are rendered at `/notes/{slug}/`.
  They require a title and date in front matter.
  """

  @behaviour Sayfa.Behaviours.ContentType

  @impl true
  def name, do: :note

  @impl true
  def directory, do: "notes"

  @impl true
  def url_prefix, do: "notes"

  @impl true
  def default_layout, do: "note"

  @impl true
  def required_fields, do: [:title, :date]
end
