{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShellNoCC {
  packages = with pkgs; [
    ffmpeg
  ];

  shellHook = ''
  # echo "Erlang/Elixir version"
  # elixir -v
  echo "Running ..."
  # mix run -e "PodcastTranscriber.latest_episode_transcription"
  # echo "Done"
  # exit
  
  iex -S mix
  '';
}
