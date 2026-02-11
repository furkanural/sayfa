defmodule Sayfa.Blocks.RecentPosts do
  @moduledoc """
  Recent posts block.

  Renders a list of the most recent posts from the site contents.

  ## Assigns

  - `:contents` — list of all site contents (injected by block helper)
  - `:limit` — number of posts to show (default: 5)

  ## Examples

      <%= @block.(:recent_posts, limit: 3) %>

  """

  @behaviour Sayfa.Behaviours.Block

  alias Sayfa.Block
  alias Sayfa.Content

  @impl true
  def name, do: :recent_posts

  @impl true
  def render(assigns) do
    contents = Map.get(assigns, :contents, [])
    limit = Map.get(assigns, :limit, 5)

    posts =
      contents
      |> Content.all_of_type("posts")
      |> Content.recent(limit)

    if posts == [] do
      ""
    else
      items =
        Enum.map_join(posts, "\n  ", fn post ->
          url = post_url(post)
          title = Block.escape_html(post.title)

          date_html =
            if post.date, do: " <time datetime=\"#{post.date}\">#{post.date}</time>", else: ""

          "<li><a href=\"#{url}\">#{title}</a>#{date_html}</li>"
        end)

      "<section class=\"recent-posts\">\n  <h2>Recent Posts</h2>\n  <ul>\n  #{items}\n  </ul>\n</section>"
    end
  end

  defp post_url(post) do
    prefix = post.meta["url_prefix"]

    case prefix do
      nil -> "/#{post.slug}/"
      "" -> "/#{post.slug}/"
      p -> "/#{p}/#{post.slug}/"
    end
  end
end
