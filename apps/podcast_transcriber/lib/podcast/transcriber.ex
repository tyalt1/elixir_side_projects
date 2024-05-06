defmodule PodcastTranscriber.Podcast.Transcriber do
  @type transcription_chunk :: %{
          text: binary(),
          start_timestamp_seconds: float(),
          end_timestamp_seconds: float()
        }

  @type audio_to_chunks_return :: %{
          transcription: list(transcription_chunk()),
          transcription_processing_seconds: integer()
        }

  @spec audio_to_chunks(binary()) :: audio_to_chunks_return()
  def audio_to_chunks(audio_file) do
    audio_to_chunks(speech_to_text_server(), audio_file)
  end

  @doc """
  Convert audio to chuncks. Takes audio file path.
  """
  @spec audio_to_chunks(Nx.Serving.t(), binary()) :: audio_to_chunks_return()
  def audio_to_chunks(server, audio_file) do
    start_time = DateTime.utc_now()
    transcription_output = Nx.Serving.run(server, {:file, audio_file})
    end_time = DateTime.utc_now()

    %{
      transcription: transcription_output.chunks,
      transcription_processing_seconds: DateTime.diff(end_time, start_time)
    }
  end

  @spec audio_to_text(binary()) :: binary()
  def audio_to_text(audio_file) do
    audio_to_text(speech_to_text_server(), audio_file)
  end

  @doc """
  Convert audio to text. Takes audio file path.
  """
  @spec audio_to_text(Nx.Serving.t(), binary()) :: binary()
  def audio_to_text(server, audio_file) do
    %{transcription: transcription} = audio_to_chunks(server, audio_file)

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
