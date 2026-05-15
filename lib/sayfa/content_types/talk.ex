defmodule Sayfa.ContentTypes.Talk do
  @moduledoc """
  Content type for conference talks and presentations.

  Talks live in `content/talks/` and are rendered at `/talks/{slug}/`.
  """

  use Sayfa.ContentTypes.Base, name: :talk, required_fields: [:title]
end
