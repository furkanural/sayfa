defmodule Sayfa.Validator do
  @moduledoc """
  Validates content front matter fields during build.

  Emits `Logger.warning/1` messages for any validation issues but does not
  fail the build — all warnings are non-blocking.

  Uses each content type's `required_fields/0` callback to determine which
  fields must be present, so custom content types are validated automatically.

  ## Examples

      contents = [%Sayfa.Content{title: "T", body: "", meta: %{"content_type" => "articles"}}]
      Sayfa.Validator.validate_all(contents)
      #=> [%Sayfa.Content{...}]  (unchanged, warnings logged)

  """

  require Logger

  alias Sayfa.Content

  @doc """
  Validates all content items, logging warnings for any issues found.

  Returns the content list unchanged.

  ## Examples

      iex> content = %Sayfa.Content{title: "T", body: "", meta: %{"content_type" => "articles"}}
      iex> Sayfa.Validator.validate_all([content]) |> length()
      1

  """
  @spec validate_all([Content.t()]) :: [Content.t()]
  def validate_all(contents) do
    Enum.each(contents, &validate_one/1)
    contents
  end

  @doc """
  Validates a single content item, logging any warnings found.

  Looks up the content type module from `meta["content_type"]` and checks
  all fields returned by `required_fields/0`.

  Returns `:ok` regardless of whether warnings were emitted.

  ## Examples

      iex> content = %Sayfa.Content{title: "T", body: "", meta: %{"content_type" => "pages"}}
      iex> Sayfa.Validator.validate_one(content)
      :ok

  """
  @spec validate_one(Content.t()) :: :ok
  def validate_one(content) do
    content_type = content.meta["content_type"]

    case find_content_type_module(content_type) do
      nil ->
        :ok

      mod ->
        validate_required_fields(content, mod.required_fields())
    end
  end

  # --- Private ---

  defp find_content_type_module(nil), do: nil

  defp find_content_type_module(type_name) when is_binary(type_name) do
    Sayfa.ContentType.find_by_directory(type_name)
  end

  defp validate_required_fields(_content, []), do: :ok

  defp validate_required_fields(content, fields) do
    Enum.each(fields, fn field ->
      if field_missing?(content, field) do
        path = content.source_path || "(unknown path)"
        Logger.warning("[sayfa] #{path}: missing `#{field}` field")
      end
    end)
  end

  defp field_missing?(content, :date), do: is_nil(content.date)

  defp field_missing?(content, :title) do
    is_nil(content.title) or content.title == ""
  end

  defp field_missing?(content, field) when is_atom(field) do
    value = Map.get(content, field) || content.meta[to_string(field)]
    is_nil(value) or value == ""
  end
end
