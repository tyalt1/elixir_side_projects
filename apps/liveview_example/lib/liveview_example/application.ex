defmodule LiveviewExample.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      LiveviewExampleWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:liveview_example, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: LiveviewExample.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: LiveviewExample.Finch},
      # Start a worker by calling: LiveviewExample.Worker.start_link(arg)
      # {LiveviewExample.Worker, arg},
      # Start to serve requests, typically the last entry
      LiveviewExampleWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: LiveviewExample.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    LiveviewExampleWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
