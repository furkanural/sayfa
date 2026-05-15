defmodule Sayfa.ContentTypes.Note do
  @moduledoc """
  Content type for short notes.

  Notes live in `content/notes/` and are rendered at `/notes/{slug}/`.
  They require a title and date in front matter.
  """

  use Sayfa.ContentTypes.Base, name: :note
end
