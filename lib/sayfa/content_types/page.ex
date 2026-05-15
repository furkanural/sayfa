defmodule Sayfa.ContentTypes.Page do
  @moduledoc """
  Content type for standalone pages.

  Pages live in `content/pages/` and are rendered at `/{slug}/` (no prefix).
  """

  use Sayfa.ContentTypes.Base, name: :page, url_prefix: "", required_fields: [:title]
end
