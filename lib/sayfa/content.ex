defmodule Sayfa.Content do
  @moduledoc """
  Content struct and parsing functions.

  Represents a fully parsed piece of content with HTML body, metadata,
  and all front matter fields resolved. This is the struct passed to templates.

  ## Parsing

  Content can be parsed from a raw string (with YAML front matter) or from
  a `Sayfa.Content.Raw` struct:

      iex> Sayfa.Content.parse("---\\ntitle: Hello\\n---\\n# World")
      {:ok, %Sayfa.Content{title: "Hello", body: "<h1>World</h1>"}}

  ## Front Matter

  Known fields are mapped to struct keys. Unknown fields are collected
  into the `meta` map:

      ---
      title: "My Post"
      custom_field: "value"
      ---

  Results in `content.title == "My Post"` and `content.meta["custom_field"] == "value"`.
  """

  alias Sayfa.Content.Raw

  @enforce_keys [:title, :body]
  defstruct [
    :title,
    :body,
    :date,
    :slug,
    :lang,
    :source_path,
    categories: [],
    tags: [],
    draft: false,
    meta: %{}
  ]

  @type t :: %__MODULE__{
          title: String.t(),
          body: String.t(),
          date: Date.t() | nil,
          slug: String.t() | nil,
          lang: atom() | nil,
          source_path: String.t() | nil,
          categories: [String.t()],
          tags: [String.t()],
          draft: boolean(),
          meta: map()
        }

  @known_keys ~w(title date slug lang categories tags draft)

  @doc """
  Parses a raw string containing YAML front matter and Markdown body.

  The string must have front matter delimited by `---` lines at the top.

  ## Examples

      iex> {:ok, content} = Sayfa.Content.parse("---\\ntitle: Hello\\n---\\n# World")
      iex> content.title
      "Hello"

  """
  @spec parse(String.t()) :: {:ok, t()} | {:error, term()}
  def parse(raw_string) when is_binary(raw_string) do
    with {:ok, front_matter, body_markdown} <- split_front_matter(raw_string),
         {:ok, html} <- Sayfa.Markdown.render(body_markdown) do
      build_content(front_matter, html)
    end
  end

  @doc """
  Parses a raw string, raising on error.

  ## Examples

      iex> content = Sayfa.Content.parse!("---\\ntitle: Hello\\n---\\n# World")
      iex> content.title
      "Hello"

  """
  @spec parse!(String.t()) :: t()
  def parse!(raw_string) do
    case parse(raw_string) do
      {:ok, content} -> content
      {:error, reason} -> raise "Content parsing failed: #{inspect(reason)}"
    end
  end

  @doc """
  Reads and parses a content file from disk.

  ## Examples

      Sayfa.Content.parse_file("content/posts/2024-01-15-hello.md")

  """
  @spec parse_file(String.t()) :: {:ok, t()} | {:error, term()}
  def parse_file(file_path) do
    case File.read(file_path) do
      {:ok, raw_string} ->
        with {:ok, content} <- parse(raw_string) do
          filename = Path.basename(file_path)
          slug = content.slug || slug_from_filename(filename)
          {:ok, %{content | source_path: file_path, slug: slug}}
        end

      {:error, reason} ->
        {:error, {:file_read_error, file_path, reason}}
    end
  end

  @doc """
  Transforms a `Sayfa.Content.Raw` struct into a `Sayfa.Content` struct.

  Renders the Markdown body to HTML and maps front matter fields.

  ## Examples

      iex> raw = %Sayfa.Content.Raw{
      ...>   path: "content/posts/hello.md",
      ...>   front_matter: %{"title" => "Hello"},
      ...>   body_markdown: "# World"
      ...> }
      iex> {:ok, content} = Sayfa.Content.from_raw(raw)
      iex> content.title
      "Hello"

  """
  @spec from_raw(Raw.t()) :: {:ok, t()} | {:error, term()}
  def from_raw(%Raw{} = raw) do
    with {:ok, html} <- Sayfa.Markdown.render(raw.body_markdown) do
      slug = slug_from_filename(raw.filename)

      case build_content(raw.front_matter, html) do
        {:ok, content} ->
          {:ok, %{content | source_path: raw.path, slug: content.slug || slug}}

        error ->
          error
      end
    end
  end

  @doc """
  Generates a URL-friendly slug from a filename.

  Strips date prefixes (e.g., `2024-01-15-`) and the `.md` extension.

  ## Examples

      iex> Sayfa.Content.slug_from_filename("2024-01-15-hello-world.md")
      "hello-world"

      iex> Sayfa.Content.slug_from_filename("about.md")
      "about"

      iex> Sayfa.Content.slug_from_filename(nil)
      nil

  """
  @spec slug_from_filename(String.t() | nil) :: String.t() | nil
  def slug_from_filename(nil), do: nil

  def slug_from_filename(filename) do
    filename
    |> Path.rootname()
    |> strip_date_prefix()
  end

  # --- Private Functions ---

  defp split_front_matter(raw_string) do
    case String.split(raw_string, ~r/\n---\s*\n/, parts: 2) do
      [maybe_front_matter, body] ->
        case String.trim_leading(maybe_front_matter) do
          "---" <> yaml_string ->
            case YamlElixir.read_from_string(yaml_string) do
              {:ok, front_matter} when is_map(front_matter) ->
                {:ok, front_matter, String.trim(body)}

              {:ok, _} ->
                {:error, :invalid_front_matter}

              {:error, reason} ->
                {:error, {:yaml_parse_error, reason}}
            end

          _ ->
            {:error, :missing_front_matter}
        end

      _ ->
        {:error, :missing_front_matter}
    end
  end

  defp build_content(front_matter, html) do
    case Map.get(front_matter, "title") do
      nil ->
        {:error, :missing_title}

      title ->
        {known, meta} = split_known_fields(front_matter)

        content = %__MODULE__{
          title: title,
          body: html,
          date: parse_date(Map.get(known, "date")),
          slug: Map.get(known, "slug"),
          lang: parse_lang(Map.get(known, "lang")),
          categories: List.wrap(Map.get(known, "categories", [])),
          tags: List.wrap(Map.get(known, "tags", [])),
          draft: Map.get(known, "draft", false),
          meta: meta
        }

        {:ok, content}
    end
  end

  defp split_known_fields(front_matter) do
    Enum.split_with(front_matter, fn {key, _} -> key in @known_keys end)
    |> then(fn {known_list, meta_list} ->
      {Map.new(known_list), Map.new(meta_list)}
    end)
  end

  defp parse_date(nil), do: nil
  defp parse_date(%Date{} = date), do: date

  defp parse_date(date_string) when is_binary(date_string) do
    case Date.from_iso8601(date_string) do
      {:ok, date} -> date
      {:error, _} -> nil
    end
  end

  defp parse_date(_), do: nil

  defp parse_lang(nil), do: nil
  defp parse_lang(lang) when is_atom(lang), do: lang
  defp parse_lang(lang) when is_binary(lang), do: String.to_atom(lang)

  defp strip_date_prefix(name) do
    case Regex.run(~r/^\d{4}-\d{2}-\d{2}-(.+)$/, name) do
      [_, slug] -> slug
      nil -> name
    end
  end
end
