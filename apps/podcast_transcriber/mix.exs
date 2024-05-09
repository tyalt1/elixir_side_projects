defmodule PodcastTranscriber.MixProject do
  use Mix.Project

  def project do
    [
      app: :podcast_transcriber,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {PodcastTranscriber.Application, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:req, "~> 0.4.14"},
      {:fast_rss, "~> 0.5.0"},
      {:bumblebee, "~> 0.5.3"},
      {:exla, "~> 0.7.1"},
      {:kino, "~> 0.12.3"}
    ]
  end
end
