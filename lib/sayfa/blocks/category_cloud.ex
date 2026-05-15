defmodule Sayfa.Blocks.CategoryCloud do
  @moduledoc """
  Category cloud block.

  Renders a flex-wrap section with category pills sized by frequency,
  each prefixed with a folder icon.

  ## Assigns

  - `:contents` — list of all site contents (injected by block helper)

  ## Examples

      <%= @block.(:category_cloud) %>

  """

  @behaviour Sayfa.Behaviours.Block

  alias Sayfa.Blocks.Cloud

  @impl true
  def name, do: :category_cloud

  @impl true
  def render(assigns), do: Cloud.render(assigns, :category)
end
