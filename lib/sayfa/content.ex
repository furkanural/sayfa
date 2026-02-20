defmodule Sayfa.Content do
  @moduledoc """
  Content struct and parsing functions.

  Represents a fully parsed piece of content with HTML body, metadata,
  and all front matter fields resolved. This is the struct passed to templates.

  ## Parsing

  Content can be parsed from a raw string (with YAML front matter) or from
  a `Sayfa.Content.Raw` struct:

      iex> {:ok, content} = Sayfa.Content.parse("---\\ntitle: Hello\\n---\\n# World")
      iex> content.title
      "Hello"
      iex> content.body =~ "World</h1>"
      true

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

  # --- Collections API ---

  @doc """
  Filters contents by content type string.

  ## Examples

      iex> posts = [%Sayfa.Content{title: "A", body: "", meta: %{"content_type" => "posts"}},
      ...>          %Sayfa.Content{title: "B", body: "", meta: %{"content_type" => "pages"}}]
      iex> Sayfa.Content.all_of_type(posts, "posts") |> length()
      1

  """
  @spec all_of_type([t()], String.t()) :: [t()]
  def all_of_type(contents, type) do
    Enum.filter(contents, fn c -> c.meta["content_type"] == type end)
  end

  @doc """
  Filters contents that have the given tag.

  ## Examples

      iex> contents = [%Sayfa.Content{title: "A", body: "", tags: ["elixir", "otp"]},
      ...>             %Sayfa.Content{title: "B", body: "", tags: ["rust"]}]
      iex> Sayfa.Content.with_tag(contents, "elixir") |> length()
      1

  """
  @spec with_tag([t()], String.t()) :: [t()]
  def with_tag(contents, tag) do
    Enum.filter(contents, fn c -> tag in c.tags end)
  end

  @doc """
  Filters contents that have the given category.

  ## Examples

      iex> contents = [%Sayfa.Content{title: "A", body: "", categories: ["programming"]},
      ...>             %Sayfa.Content{title: "B", body: "", categories: ["cooking"]}]
      iex> Sayfa.Content.with_category(contents, "programming") |> length()
      1

  """
  @spec with_category([t()], String.t()) :: [t()]
  def with_category(contents, category) do
    Enum.filter(contents, fn c -> category in c.categories end)
  end

  @doc """
  Sorts contents by date.

  Items with `nil` dates are pushed to the end.

  ## Options

  - `:desc` (default) — newest first
  - `:asc` — oldest first

  ## Examples

      iex> contents = [%Sayfa.Content{title: "Old", body: "", date: ~D[2024-01-01]},
      ...>             %Sayfa.Content{title: "New", body: "", date: ~D[2024-06-01]}]
      iex> sorted = Sayfa.Content.sort_by_date(contents)
      iex> hd(sorted).title
      "New"

  """
  @spec sort_by_date([t()], :asc | :desc) :: [t()]
  def sort_by_date(contents, order \\ :desc) do
    {with_dates, without_dates} = Enum.split_with(contents, fn c -> c.date != nil end)

    sorted =
      case order do
        :desc -> Enum.sort_by(with_dates, & &1.date, {:desc, Date})
        :asc -> Enum.sort_by(with_dates, & &1.date, {:asc, Date})
      end

    sorted ++ without_dates
  end

  @doc """
  Returns the N most recent contents (sorted by date descending).

  ## Examples

      iex> contents = [%Sayfa.Content{title: "A", body: "", date: ~D[2024-01-01]},
      ...>             %Sayfa.Content{title: "B", body: "", date: ~D[2024-06-01]},
      ...>             %Sayfa.Content{title: "C", body: "", date: ~D[2024-03-01]}]
      iex> Sayfa.Content.recent(contents, 2) |> Enum.map(& &1.title)
      ["B", "C"]

  """
  @spec recent([t()], pos_integer()) :: [t()]
  def recent(contents, n) do
    contents |> sort_by_date(:desc) |> Enum.take(n)
  end

  @doc """
  Groups contents by tag.

  Returns a map where each key is a tag and the value is a list
  of contents that have that tag.

  ## Examples

      iex> contents = [%Sayfa.Content{title: "A", body: "", tags: ["elixir", "otp"]},
      ...>             %Sayfa.Content{title: "B", body: "", tags: ["elixir"]}]
      iex> groups = Sayfa.Content.group_by_tag(contents)
      iex> length(groups["elixir"])
      2
      iex> length(groups["otp"])
      1

  """
  @spec group_by_tag([t()]) :: %{String.t() => [t()]}
  def group_by_tag(contents) do
    Enum.reduce(contents, %{}, fn content, acc ->
      Enum.reduce(content.tags, acc, fn tag, inner_acc ->
        Map.update(inner_acc, tag, [content], &[content | &1])
      end)
    end)
    |> Map.new(fn {k, v} -> {k, Enum.reverse(v)} end)
  end

  @doc """
  Groups contents by category.

  Returns a map where each key is a category and the value is a list
  of contents that have that category.

  ## Examples

      iex> contents = [%Sayfa.Content{title: "A", body: "", categories: ["programming"]},
      ...>             %Sayfa.Content{title: "B", body: "", categories: ["programming", "elixir"]}]
      iex> groups = Sayfa.Content.group_by_category(contents)
      iex> length(groups["programming"])
      2

  """
  @spec group_by_category([t()]) :: %{String.t() => [t()]}
  def group_by_category(contents) do
    Enum.reduce(contents, %{}, fn content, acc ->
      Enum.reduce(content.categories, acc, fn cat, inner_acc ->
        Map.update(inner_acc, cat, [content], &[content | &1])
      end)
    end)
    |> Map.new(fn {k, v} -> {k, Enum.reverse(v)} end)
  end

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
  Reads a file and returns a `Sayfa.Content.Raw` struct without rendering Markdown.

  This is used by the builder to allow hooks to modify the raw content
  before Markdown rendering.

  ## Examples

      {:ok, raw} = Sayfa.Content.parse_raw_file("content/posts/hello.md")
      raw.front_matter["title"]
      #=> "Hello"

  """
  @spec parse_raw_file(String.t()) :: {:ok, Raw.t()} | {:error, term()}
  def parse_raw_file(file_path) do
    case File.read(file_path) do
      {:ok, raw_string} ->
        with {:ok, front_matter, body_markdown} <- split_front_matter(raw_string) do
          {:ok,
           %Raw{
             path: file_path,
             front_matter: front_matter,
             body_markdown: body_markdown,
             filename: Path.basename(file_path)
           }}
        end

      {:error, reason} ->
        {:error, {:file_read_error, file_path, reason}}
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
          date = content.date || date_from_filename(filename)
          {:ok, %{content | source_path: file_path, slug: slug, date: date}}
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
      filename_date = date_from_filename(raw.filename)

      case build_content(raw.front_matter, html) do
        {:ok, content} ->
          {:ok,
           %{
             content
             | source_path: raw.path,
               slug: content.slug || slug,
               date: content.date || filename_date
           }}

        error ->
          error
      end
    end
  end

  @doc """
  Returns the URL path for a content item.

  Combines `lang_prefix`, `url_prefix`, and `slug` from the content's metadata
  to build the correct path. This is the single source of truth for content URLs.

  ## Examples

      iex> content = %Sayfa.Content{title: "T", body: "", slug: "hello", meta: %{"url_prefix" => "posts", "lang_prefix" => ""}}
      iex> Sayfa.Content.url(content)
      "/posts/hello"

      iex> content = %Sayfa.Content{title: "T", body: "", slug: "merhaba", meta: %{"url_prefix" => "posts", "lang_prefix" => "tr"}}
      iex> Sayfa.Content.url(content)
      "/tr/posts/merhaba"

      iex> content = %Sayfa.Content{title: "T", body: "", slug: "index", meta: %{"url_prefix" => "", "lang_prefix" => ""}}
      iex> Sayfa.Content.url(content)
      "/"

  """
  @spec url(t()) :: String.t()
  def url(content) do
    prefix = content.meta["url_prefix"] || ""
    lang_prefix = content.meta["lang_prefix"] || ""

    base =
      case {prefix, content.slug} do
        {"", "index"} -> "/"
        {"", slug} -> "/#{slug}"
        {p, "index"} -> "/#{p}"
        {p, slug} -> "/#{p}/#{slug}"
      end

    case lang_prefix do
      "" -> base
      lp -> "/#{lp}#{base}"
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

  @doc """
  Extracts a `Date` from a filename's `YYYY-MM-DD-` prefix.

  Returns `nil` if the filename has no date prefix or is `nil`.

  ## Examples

      iex> Sayfa.Content.date_from_filename("2024-01-15-hello-world.md")
      ~D[2024-01-15]

      iex> Sayfa.Content.date_from_filename("about.md")
      nil

      iex> Sayfa.Content.date_from_filename(nil)
      nil

  """
  @spec date_from_filename(String.t() | nil) :: Date.t() | nil
  def date_from_filename(nil), do: nil

  def date_from_filename(filename) do
    case Regex.run(~r/^(\d{4}-\d{2}-\d{2})-/, Path.rootname(filename)) do
      [_, date_str] -> parse_date(date_str)
      nil -> nil
    end
  end

  # --- Private Functions ---

  defp split_front_matter(raw_string) do
    with [maybe_front_matter, body] <- split_on_delimiter(raw_string),
         "---" <> yaml_string <- String.trim_leading(maybe_front_matter) do
      parse_yaml_front_matter(yaml_string, body)
    else
      _ -> {:error, :missing_front_matter}
    end
  end

  defp split_on_delimiter(raw_string) do
    String.split(raw_string, ~r/\n---\s*\n/, parts: 2)
  end

  defp parse_yaml_front_matter(yaml_string, body) do
    case YamlElixir.read_from_string(yaml_string) do
      {:ok, front_matter} when is_map(front_matter) ->
        {:ok, front_matter, String.trim(body)}

      {:ok, _} ->
        {:error, :invalid_front_matter}

      {:error, reason} ->
        {:error, {:yaml_parse_error, reason}}
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
