defmodule Crush.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      Crush.Supervisor,
      # Start the Telemetry supervisor
      CrushWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Crush.PubSub},
      # Start the Endpoint (http/https)
      CrushWeb.Endpoint
      # Start a worker by calling: Crush.Worker.start_link(arg)
      # {Crush.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Crush.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    CrushWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
