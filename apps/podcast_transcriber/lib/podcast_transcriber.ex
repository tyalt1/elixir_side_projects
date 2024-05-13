defmodule PodcastTranscriber do
  @moduledoc """
  Documentation for `PodcastTranscriber`.
  """

  alias PodcastTranscriber.Podcast.Episode
  import PodcastTranscriber.Podcast.Transcriber, only: [audio_to_text: 1]

  def latest_episode_transcription do
    rss_feed_url = "https://feeds.fireside.fm/elixiroutlaws/rss"

    latest_episode = rss_feed_url |> Episode.episodes_from_rss_url() |> Enum.at(0)
    latest_episode_file = latest_episode.url

    transcription_text = """
    ## Transcription

    #{audio_to_text(latest_episode_file)}
    """

    episode_text = Episode.to_text(latest_episode, transcription_text)

    IO.puts(episode_text)
  end
end
