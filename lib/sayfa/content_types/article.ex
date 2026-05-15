defmodule Sayfa.ContentTypes.Article do
  @moduledoc """
  Content type for articles.

  Articles live in `content/articles/` and are rendered at `/articles/{slug}/`.
  They require a title and date in front matter.
  """

  use Sayfa.ContentTypes.Base, name: :article
end
