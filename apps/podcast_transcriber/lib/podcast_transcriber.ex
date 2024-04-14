defmodule PodcastTranscriber do
  @moduledoc """
  Documentation for `PodcastTranscriber`.
  """

  alias PodcastTranscriber.Podcast.Episode

  def latest_episode_transcription do
    rss_feed_url = "https://feeds.fireside.fm/elixiroutlaws/rss"

    latest_episode = rss_feed_url |> Episode.episodes_from_rss_url() |> Enum.at(0)

    %{transcription: transcription} = Episode.transcription(latest_episode)

    IO.puts(Episode.transcription_to_text(latest_episode.show_title, transcription))
  end
end