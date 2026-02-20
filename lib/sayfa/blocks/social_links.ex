defmodule Sayfa.Blocks.SocialLinks do
  @moduledoc """
  Social links block.

  Renders card-style social media links with platform icons.

  ## Assigns

  - `:links` — list of `{name, url}` tuples (required)

  ## Examples

      <%= @block.(:social_links, links: [{"GitHub", "https://github.com/me"}, {"Twitter", "https://twitter.com/me"}]) %>

  """

  @behaviour Sayfa.Behaviours.Block

  alias Sayfa.Block

  @impl true
  def name, do: :social_links

  @impl true
  def render(assigns) do
    links = Map.get(assigns, :links, [])

    if links == [] do
      ""
    else
      items = Enum.map_join(links, "\n  ", &render_link/1)

      "<div class=\"flex flex-wrap gap-3\">\n  #{items}\n</div>"
    end
  end

  defp render_link({label, url}) do
    icon = social_icon(label)
    escaped_label = Block.escape_html(label)
    escaped_url = Block.escape_html(url)
    rel = rel_attr(label)

    "<a href=\"#{escaped_url}\" rel=\"#{rel}\" class=\"inline-flex items-center gap-2 px-4 py-2.5 rounded-lg border border-slate-200/70 dark:border-slate-800 text-sm text-slate-600 dark:text-slate-300 hover:border-primary/30 hover:text-primary dark:hover:border-primary-700/40 dark:hover:text-primary-400 bg-slate-50 dark:bg-slate-800/50\">#{icon} #{escaped_label}</a>"
  end

  defp rel_attr(label) do
    if String.contains?(String.downcase(label), "mastodon"),
      do: "me noopener",
      else: "noopener"
  end

  defp social_icon(label) do
    case String.downcase(label) do
      "github" ->
        ~s(<svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24"><path d="M15 22v-4a4.8 4.8 0 0 0-1-3.5c3 0 6-2 6-5.5.08-1.25-.27-2.48-1-3.5.28-1.15.28-2.35 0-3.5 0 0-1 0-3 1.5-2.64-.5-5.36-.5-8 0C6 2 5 2 5 2c-.3 1.15-.3 2.35 0 3.5A5.403 5.403 0 0 0 4 9c0 3.5 3 5.5 6 5.5-.39.49-.68 1.05-.85 1.65-.17.6-.22 1.23-.15 1.85v4"/><path d="M9 18c-4.51 2-5-2-7-2"/></svg>)

      x when x in ["twitter", "x", "x / twitter"] ->
        ~s(<svg class="w-4 h-4" fill="currentColor" stroke="none" viewBox="0 0 24 24"><path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z"/></svg>)

      "mastodon" ->
        ~s(<svg class="w-4 h-4" fill="currentColor" stroke="none" viewBox="0 0 24 24"><path d="M21.327 8.566c0-4.339-2.843-5.61-2.843-5.61-1.433-.658-3.894-.935-6.451-.956h-.063c-2.557.021-5.016.298-6.45.956 0 0-2.843 1.272-2.843 5.61 0 .993-.019 2.181.012 3.441.103 4.243.778 8.425 4.701 9.463 1.809.479 3.362.579 4.612.51 2.268-.126 3.541-.809 3.541-.809l-.075-1.646s-1.621.511-3.441.449c-1.804-.062-3.707-.194-3.999-2.409a4.5 4.5 0 0 1-.04-.621s1.77.432 4.014.535c1.372.063 2.658-.08 3.965-.236 2.506-.299 4.688-1.843 4.962-3.254.434-2.223.398-5.424.398-5.424zm-3.353 5.59h-2.081V9.057c0-1.075-.452-1.62-1.357-1.62-1 0-1.501.647-1.501 1.927v2.791h-2.069V9.364c0-1.28-.501-1.927-1.502-1.927-.905 0-1.357.546-1.357 1.62v5.099H6.026V8.903c0-1.074.273-1.927.823-2.558.566-.631 1.307-.955 2.228-.955 1.065 0 1.872.41 2.405 1.228l.518.869.519-.869c.533-.818 1.34-1.228 2.405-1.228.92 0 1.662.324 2.228.955.549.631.822 1.484.822 2.558z"/></svg>)

      "goodreads" ->
        ~s(<svg class="w-4 h-4" fill="currentColor" stroke="none" viewBox="0 0 24 24"><path d="M11.43 23.995c-3.608-.208-6.274-2.077-7.927-5.078-.702-1.27-.955-2.623-1.17-4.013-.213-1.395-.107-2.791.203-4.167.547-2.393 1.78-4.335 3.865-5.685 1.398-.904 2.95-1.322 4.622-1.263 1.727.06 3.244.675 4.534 1.858.171.158.336.323.516.498V1h1.429v14.972c-.003 1.236-.063 2.473-.334 3.686-.373 1.625-1.175 2.96-2.49 3.967-1.35 1.034-2.888 1.394-4.556 1.39-.094 0-.188-.013-.282-.02h-.002l.002.002-.41-.002zm6.064-13.33c-.03-.158-.066-.315-.088-.474-.196-1.408-.527-2.77-1.29-3.99-.534-.855-1.22-1.53-2.123-1.975-1.626-.804-3.276-.81-4.878-.06-1.088.507-1.876 1.335-2.468 2.345-.73 1.247-1.054 2.61-1.157 4.035-.079 1.083-.075 2.16.143 3.228.237 1.16.637 2.25 1.363 3.202.963 1.263 2.217 2.012 3.78 2.147 1.478.128 2.795-.253 3.876-1.21.816-.722 1.372-1.61 1.764-2.605.344-.87.52-1.786.632-2.717.055-.46.086-.924.128-1.386l.003-.04.005-.04.004-.04.003-.04.004-.04.005-.04.003-.04.004-.04.005-.04.003-.04.004-.04.005-.04.003-.04.004-.04.005-.04v-.03l.003-.028-.003-.05.017-.17zm-.004 7.094v2.1c-.035.324-.065.65-.105.975-.16 1.274-.547 2.46-1.377 3.475-1.19 1.453-2.74 2.117-4.58 2.125-1.2.005-2.328-.253-3.345-.894-1.26-.794-2.08-1.943-2.583-3.324-.044-.12-.093-.237-.14-.356l.01-.005.012.01c.251.36.493.727.754 1.08.826 1.12 1.862 1.99 3.162 2.506 1.478.587 2.988.58 4.466.022 1.24-.468 2.192-1.32 2.912-2.43.593-.913.93-1.927 1.103-3.005.053-.334.088-.672.131-1.008l.005-.04.004-.04.005-.04.004-.04.004-.04.005-.04.004-.04.004-.04.005-.04.004-.04.004-.04.005-.04.004-.04.004-.04.005-.04.004-.033.003-.027-.004-.05.018-.163z"/></svg>)

      "email" ->
        ~s(<svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24"><rect width="20" height="16" x="2" y="4" rx="2"/><path d="m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7"/></svg>)

      "rss" ->
        ~s(<svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24"><path d="M4 11a9 9 0 0 1 9 9"/><path d="M4 4a16 16 0 0 1 16 16"/><circle cx="5" cy="19" r="1"/></svg>)

      _ ->
        ~s(<svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24"><path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"/><path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"/></svg>)
    end
  end
end
