defmodule PodcastTranscriber.Podcast.Episode do
  defstruct show_title: nil, episode_title: nil, url: nil
  alias __MODULE__

  @type t :: %Episode{}

  @spec episodes_from_rss_url(binary()) :: [t()]
  def episodes_from_rss_url(rss_feed_url) do
    %{body: rss_body} = Req.get!(rss_feed_url)
    {:ok, rss_feed} = FastRSS.parse_rss(rss_body)

    show_title = rss_feed["title"]

    Enum.map(rss_feed["items"], fn item ->
      %Episode{
        show_title: show_title,
        episode_title: item["title"],
        url: item["enclosure"]["url"]
      }
    end)
  end

  @spec local_file(t()) :: binary()
  def local_file(%Episode{url: url, show_title: show_title, episode_title: episode_title}) do
    local_file(url, Path.join(show_title, episode_title))
  end

  @spec local_file(binary(), binary()) :: binary()
  def local_file(url, prefix \\ "") when is_binary(url) do
    local_path =
      Path.join([
        System.tmp_dir!(),
        "podcast-download",
        prefix,
        URI.parse(url).path |> Path.basename()
      ])

    if !File.exists?(local_path) do
      download_file(url, local_path)
    end

    local_path
  end

  # download file
  defp download_file(url, out_path) do
    # make sure path exists
    out_path |> Path.dirname() |> File.mkdir_p!()
    Req.get!(url: url, into: File.stream!(out_path))
  end

  def to_text(%Episode{show_title: show_title, episode_title: episode_title}, body) do
    """
    # #{show_title}
    ## #{episode_title}

    #{body}
    """
  end
end
