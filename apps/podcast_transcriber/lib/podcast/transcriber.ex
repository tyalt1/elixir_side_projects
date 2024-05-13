defmodule PodcastTranscriber.Podcast.Transcriber do
  require Logger

  @type transcription_chunk :: %{
          text: binary(),
          start_timestamp_seconds: float(),
          end_timestamp_seconds: float()
        }

  @type audio_to_chunks_return :: %{
          transcription: list(transcription_chunk()),
          transcription_processing_seconds: integer()
        }

  def child_spec do
    {Nx.Serving, name: PodcastTranscriber.Whisper, serving: speech_to_text_server()}
  end

  @doc """
  Convert audio to chuncks. Takes audio file path.
  """
  @spec audio_to_chunks(binary()) :: audio_to_chunks_return()
  def audio_to_chunks(audio_file) do
    start_time = DateTime.utc_now()
    serving_input = case String.contains?(audio_file, "http") do
      true -> {:file_url, audio_file}
      false -> {:file, audio_file}
    end
    transcription_output = Nx.Serving.batched_run(PodcastTranscriber.Whisper, serving_input)
    end_time = DateTime.utc_now()
    seconds = DateTime.diff(end_time, start_time)

    Logger.info("generated transcription", transcription_processing_seconds: seconds)

    %{
      transcription: transcription_output.chunks,
      transcription_processing_seconds: seconds
    }
  end

  @doc """
  Convert audio to text. Takes audio file path.
  """
  @spec audio_to_text(binary()) :: binary()
  def audio_to_text(audio_file) do
    %{transcription: transcription} = audio_to_chunks(audio_file)

    chunk_to_line = fn chunk ->
      "- #{timestamp_hhmmss(chunk.start_timestamp_seconds)} | #{chunk.text}\n"
    end

    transcription
    |> Enum.map(chunk_to_line)
    |> Enum.join()
  end

  # --- AI ---
  @doc """
  Default speech to text configuration.
  """
  @spec speech_to_text_server() :: Nx.Serving.t()
  def speech_to_text_server(opts \\ []) do
    stream = Keyword.get(opts, :stream, false)
    chunk_num_seconds = Keyword.get(opts, :chunk_num_seconds, 30)
    batch_size = Keyword.get(opts, :batch_size, 10)

    whisper = {:hf, "openai/whisper-tiny"}
    {:ok, model_info} = Bumblebee.load_model(whisper, backend: EXLA.Backend)
    {:ok, featurizer} = Bumblebee.load_featurizer(whisper)
    {:ok, tokenizer} = Bumblebee.load_tokenizer(whisper)
    {:ok, generation_config} = Bumblebee.load_generation_config(whisper)

    serving =
      Bumblebee.Audio.speech_to_text_whisper(model_info, featurizer, tokenizer, generation_config,
        chunk_num_seconds: chunk_num_seconds,
        timestamps: :segments,
        defn_options: [compiler: EXLA, lazy_transfers: :never],
        compile: [batch_size: batch_size],
        stream: stream
      )

    serving
    |> Nx.Serving.client_preprocessing(fn
      {:file_url, url} ->
        {:ok, file_path} = download_file(url)

        {stream, info} = serving.client_preprocessing.({:file, file_path})

        {stream, [{:file_needs_disposal, file_path}] ++ Tuple.to_list(info)}

      input ->
        serving.client_preprocessing.(input)
    end)
    |> Nx.Serving.client_postprocessing(fn
      output_or_stream, [{:file_needs_disposal, file_path} | rest] ->
        File.rm(file_path)

        serving.client_postprocessing.(output_or_stream, List.to_tuple(rest))

      output_or_stream, _info ->
        serving.client_postprocessing.(output_or_stream, {})
    end)
  end

  defp download_file(url) do
    download_directory = Path.join(System.tmp_dir!(), "downloads")
    File.mkdir_p!(download_directory)

    filename = URI.parse(url) |> Map.fetch!(:path) |> Path.basename()
    out_path = Path.join(download_directory, filename)

    with {:ok, _res} <- Req.get(url: url, into: File.stream!(out_path)) do
      {:ok, out_path}
    end
  end

  # --- UTIL ---

  # timestamp(0.0) => "00:00:00"
  # timestamp(2896.4) => "00:48:16"
  @spec timestamp_hhmmss(number()) :: binary()
  defp timestamp_hhmmss(seconds) do
    seconds = floor(seconds)
    hours = div(seconds, 3600)
    minutes = div(seconds, 60)
    seconds = rem(seconds, 60)

    [hours, minutes, seconds]
    |> Enum.map(fn x -> String.pad_leading(to_string(x), 2, "0") end)
    |> Enum.join(":")
  end
end
