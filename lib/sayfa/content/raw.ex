defmodule Sayfa.Content.Raw do
  @moduledoc """
  Intermediate representation of parsed content before Markdown rendering.

  This struct holds the raw data extracted from a content file:
  the file path, parsed YAML front matter, and the unparsed Markdown body.
  It is used as an intermediate step before transforming into `Sayfa.Content`.

  ## Examples

      %Sayfa.Content.Raw{
        path: "content/posts/2024-01-15-hello.md",
        front_matter: %{"title" => "Hello", "date" => ~D[2024-01-15]},
        body_markdown: "# Hello World\\n\\nContent here.",
        filename: "2024-01-15-hello.md"
      }

  """

  @enforce_keys [:path, :front_matter, :body_markdown]
  defstruct [:path, :front_matter, :body_markdown, :filename]

  @type t :: %__MODULE__{
          path: String.t(),
          front_matter: map(),
          body_markdown: String.t(),
          filename: String.t() | nil
        }
end
