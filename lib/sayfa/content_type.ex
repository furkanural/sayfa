defmodule Sayfa.ContentType do
  @moduledoc """
  Registry and lookup functions for content types.

  Maps directory names and type names to content type modules.
  By default, five built-in types are registered: post, note, project,
  talk, and page.

  Custom types can be added via application config:

      config :sayfa, :content_types, [MyApp.ContentTypes.Recipe | Sayfa.ContentType.default_types()]

  ## Examples

      iex> Sayfa.ContentType.find_by_name(:post)
      Sayfa.ContentTypes.Post

      iex> Sayfa.ContentType.find_by_directory("posts")
      Sayfa.ContentTypes.Post

      iex> Sayfa.ContentType.find_by_directory("unknown")
      nil

  """

  @doc """
  Returns the list of built-in content type modules.

  ## Examples

      iex> length(Sayfa.ContentType.default_types())
      5

  """
  @spec default_types() :: [module()]
  def default_types do
    [
      Sayfa.ContentTypes.Post,
      Sayfa.ContentTypes.Note,
      Sayfa.ContentTypes.Project,
      Sayfa.ContentTypes.Talk,
      Sayfa.ContentTypes.Page
    ]
  end

  @doc """
  Returns all registered content type modules.

  Reads from application config, falling back to `default_types/0`.

  ## Examples

      iex> types = Sayfa.ContentType.all()
      iex> is_list(types)
      true

  """
  @spec all() :: [module()]
  def all do
    Application.get_env(:sayfa, :content_types, default_types())
  end

  @doc """
  Finds a content type module by its directory name.

  ## Examples

      iex> Sayfa.ContentType.find_by_directory("posts")
      Sayfa.ContentTypes.Post

      iex> Sayfa.ContentType.find_by_directory("nonexistent")
      nil

  """
  @spec find_by_directory(String.t()) :: module() | nil
  def find_by_directory(directory) do
    Enum.find(all(), fn mod -> mod.directory() == directory end)
  end

  @doc """
  Finds a content type module by its atom name.

  ## Examples

      iex> Sayfa.ContentType.find_by_name(:post)
      Sayfa.ContentTypes.Post

      iex> Sayfa.ContentType.find_by_name(:unknown)
      nil

  """
  @spec find_by_name(atom()) :: module() | nil
  def find_by_name(name) do
    Enum.find(all(), fn mod -> mod.name() == name end)
  end
end
