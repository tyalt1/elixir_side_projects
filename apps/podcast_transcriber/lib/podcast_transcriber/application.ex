defmodule PodcastTranscriber.Application do
  use Application

  alias PodcastTranscriber.Podcast.Transcriber

  @doc false
  @impl true
  def start(_type, _args) do
    children = [
      Transcriber.child_spec()
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: __MODULE__)
  end
end
