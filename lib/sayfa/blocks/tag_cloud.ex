defmodule Sayfa.Blocks.TagCloud do
  @moduledoc """
  Tag cloud block.

  Renders a flex-wrap section with tag pills sized by frequency,
  each prefixed with a hash icon.

  ## Assigns

  - `:contents` — list of all site contents (injected by block helper)

  ## Examples

      <%= @block.(:tag_cloud) %>

  """

  @behaviour Sayfa.Behaviours.Block

  alias Sayfa.Blocks.Cloud

  @impl true
  def name, do: :tag_cloud

  @impl true
  def render(assigns), do: Cloud.render(assigns, :tag)
end
