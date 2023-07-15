defmodule IST.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      ISTWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: IST.PubSub},
      # Presence
      ISTWeb.Presence,
      # Start the Endpoint (http/https)
      ISTWeb.Endpoint,
      # Start a worker by calling: IST.Worker.start_link(arg)
      # {IST.Worker, arg}
      IST.Game
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: IST.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ISTWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
