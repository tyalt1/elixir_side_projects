defmodule PodcastTranscriber.Podcast.Episode do
  defstruct title: nil, url: nil, local_file: nil, meta: %{}
  alias __MODULE__

  @type t :: %Episode{}

  @spec episodes_from_rss_url(binary()) :: [t()]
  def episodes_from_rss_url(rss_feed_url) do
    %{body: rss_body} = Req.get!(rss_feed_url)
    {:ok, rss_feed} = FastRSS.parse_rss(rss_body)

    meta = %{
      show_title: rss_feed["title"]
    }

    Enum.map(rss_feed["items"], fn item ->
      %Episode{
        title: item["title"],
        url: item["enclosure"]["url"],
        meta: meta
      }
    end)
  end

  @spec local_file(t() | binary()) :: binary()
  def local_file(%Episode{url: url}) do
    local_file(url)
  end

  def local_file(url) when is_binary(url) do
    download_directory = Path.join(System.tmp_dir!(), "podcast-downloads")
    filename = URI.parse(url) |> Map.fetch!(:path) |> Path.basename()
    out_path = Path.join(download_directory, filename)

    if !File.exists?(out_path) do
      download_file(url, out_path)
    end

    out_path
  end

  # download file
  defp download_file(url, out_path) do
    out_path |> Path.dirname() |> File.mkdir_p!()
    Req.get!(url: url, into: File.stream!(out_path))
  end

  @doc """
  Takes %Episode and adds local file
  """
  def with_local_file(ep = %Episode{url: url}) do
    %Episode{ep | local_file: local_file(url)}
  end

  def transcription(file, opts \\ []) when is_binary(file) do
    server = case Keyword.get(opts, :server) do
      nil -> speech_to_text_server()
      x -> x
    end

    start_time = DateTime.utc_now()
    transcription_output = Nx.Serving.run(server, {:file, file})
    end_time = DateTime.utc_now()

    %{
      transcription: transcription_output.chunks,
      transcription_processing_seconds: DateTime.diff(end_time, start_time)
    }
  end

  def transcription_to_text(%Episode{meta: %{show_title: title}}, transcription) do
    transcription_to_text(title, transcription)
  end

  def transcription_to_text(title, transcription) do
    body =
      Enum.map(transcription, fn chunk ->
        "- #{timestamp(chunk.start_timestamp_seconds)} | #{chunk.text}"
      end)
      |> Enum.join("\n")

    """
    # #{title}

    ## Transcript

    #{body}
    """
  end

  def transcription_to_markdown(title, transcription) do
    transcription_to_text(title, transcription)
    |> Kino.Markdown.new()
  end

  # --- UTIL ---
  @doc """
  Converts seconds to

  iex> timestamp(0.0)
  "00:00:00"
  iex> timestamp(2896.4)
  "00:48:16"
  """
  @spec timestamp(number()) :: binary()
  defp timestamp(seconds) do
    seconds = floor(seconds)
    hours = div(seconds, 3600) |> to_string() |> String.pad_leading(2, "0")
    minutes = div(seconds, 60) |> to_string() |> String.pad_leading(2, "0")
    seconds = rem(seconds, 60) |> to_string() |> String.pad_leading(2, "0")

    "#{hours}:#{minutes}:#{seconds}"
  end

  # --- AI ---
  @spec speech_to_text_server() :: Nx.Serving.t()
  defp speech_to_text_server do
    {:ok, whisper} = Bumblebee.load_model({:hf, "openai/whisper-tiny"})
    {:ok, featurizer} = Bumblebee.load_featurizer({:hf, "openai/whisper-tiny"})
    {:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, "openai/whisper-tiny"})
    {:ok, generation_config} = Bumblebee.load_generation_config({:hf, "openai/whisper-tiny"})

    Bumblebee.Audio.speech_to_text_whisper(whisper, featurizer, tokenizer, generation_config,
      defn_options: [compiler: EXLA],
      chunk_num_seconds: 30,
      timestamps: :segments
    )
  end
end
