defmodule PodcastTranscriber do
  @moduledoc """
  Documentation for `PodcastTranscriber`.
  """

  alias PodcastTranscriber.Podcast.Episode
  alias PodcastTranscriber.Podcast.Transcriber

  def latest_episode_transcription do
    rss_feed_url = "https://feeds.fireside.fm/elixiroutlaws/rss"

    latest_episode = rss_feed_url |> Episode.episodes_from_rss_url() |> Enum.at(0)
    latest_episode_file = Episode.local_file(latest_episode)

    transcription_text = """
    ## Transcription

    #{Transcriber.audio_to_text(latest_episode_file)}
    """

    IO.puts(Episode.to_text(latest_episode, transcription_text))
  end
end
