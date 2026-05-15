defmodule Sayfa.ContentTypes.Project do
  @moduledoc """
  Content type for project showcases.

  Projects live in `content/projects/` and are rendered at `/projects/{slug}/`.
  """

  use Sayfa.ContentTypes.Base, name: :project, required_fields: [:title]
end
