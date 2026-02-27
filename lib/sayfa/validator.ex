defmodule Sayfa.Validator do
  @moduledoc """
  Validates content front matter fields during build.

  Emits `Logger.warning/1` messages for any validation issues but does not
  fail the build — all warnings are non-blocking.

  ## Validations

  - Posts and notes without a `date` field get a warning.

  ## Examples

      contents = [%Sayfa.Content{title: "T", body: "", meta: %{"content_type" => "posts"}}]
      Sayfa.Validator.validate_all(contents)
      #=> [%Sayfa.Content{...}]  (unchanged, warnings logged)

  """

  require Logger

  @dated_content_types ~w(posts notes)

  @doc """
  Validates all content items, logging warnings for any issues found.

  Returns the content list unchanged.

  ## Examples

      iex> content = %Sayfa.Content{title: "T", body: "", meta: %{"content_type" => "posts"}}
      iex> Sayfa.Validator.validate_all([content]) |> length()
      1

  """
  @spec validate_all([Sayfa.Content.t()]) :: [Sayfa.Content.t()]
  def validate_all(contents) do
    Enum.each(contents, &validate_one/1)
    contents
  end

  @doc """
  Validates a single content item, logging any warnings found.

  Returns `:ok` regardless of whether warnings were emitted.

  ## Examples

      iex> content = %Sayfa.Content{title: "T", body: "", meta: %{"content_type" => "pages"}}
      iex> Sayfa.Validator.validate_one(content)
      :ok

  """
  @spec validate_one(Sayfa.Content.t()) :: :ok
  def validate_one(content) do
    type = content.meta["content_type"]
    check_date(content, type)
    :ok
  end

  defp check_date(content, type) when type in @dated_content_types do
    if is_nil(content.date) do
      path = content.source_path || "(unknown path)"

      Logger.warning("[sayfa] #{path}: missing `date` field (#{type} content should have a date)")
    end
  end

  defp check_date(_content, _type), do: :ok
end
