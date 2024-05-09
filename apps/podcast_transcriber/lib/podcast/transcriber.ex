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

  def start_link do
    {_, opts} = child_spec()
    Nx.Serving.start_link(opts)
  end

  @doc """
  Convert audio to chuncks. Takes audio file path.
  """
  @spec audio_to_chunks(binary()) :: audio_to_chunks_return()
  def audio_to_chunks(audio_file) do
    start_time = DateTime.utc_now()
    transcription_output = Nx.Serving.batched_run(PodcastTranscriber.Whisper, {:file, audio_file})
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
  def speech_to_text_server do
    whisper = {:hf, "openai/whisper-tiny"}
    {:ok, model_info} = Bumblebee.load_model(whisper)
    {:ok, featurizer} = Bumblebee.load_featurizer(whisper)
    {:ok, tokenizer} = Bumblebee.load_tokenizer(whisper)
    {:ok, generation_config} = Bumblebee.load_generation_config(whisper)

    Bumblebee.Audio.speech_to_text_whisper(model_info, featurizer, tokenizer, generation_config,
      defn_options: [compiler: EXLA],
      chunk_num_seconds: 30,
      timestamps: :segments
    )
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
