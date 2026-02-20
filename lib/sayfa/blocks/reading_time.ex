defmodule Sayfa.Blocks.ReadingTime do
  @moduledoc """
  Reading time block.

  Renders a `<span>` with the estimated reading time from content metadata.
  Reads `content.meta["reading_time"]` which is populated by the builder's enrichment stage.

  ## Assigns

  - `:content` — current `Sayfa.Content` struct with `meta["reading_time"]`

  ## Examples

      <%= @block.(:reading_time) %>

  """

  @behaviour Sayfa.Behaviours.Block

  @impl true
  def name, do: :reading_time

  @impl true
  def render(assigns) do
    content = Map.get(assigns, :content)
    t = Map.get(assigns, :t, Sayfa.I18n.default_translate_function())
    minutes = get_reading_time(content)

    if minutes do
      label = "#{minutes} #{t.("min_read")}"

      "<span class=\"inline-flex items-center gap-1.5\"><svg class=\"w-4 h-4\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"1.5\" viewBox=\"0 0 24 24\"><circle cx=\"12\" cy=\"12\" r=\"10\"/><polyline points=\"12 6 12 12 16 14\"/></svg>#{label}</span>"
    else
      ""
    end
  end

  defp get_reading_time(nil), do: nil
  defp get_reading_time(%{meta: %{"reading_time" => %{minutes: m}}}), do: m
  defp get_reading_time(%{meta: %{"reading_time" => m}}) when is_integer(m), do: m
  defp get_reading_time(_), do: nil
end
