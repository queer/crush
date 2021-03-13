defmodule Crush.Application do
  @moduledoc false

  use Application
  alias Crush.Utils
  require Logger

  def start(_type, _args) do
    cookie = :crush |> Application.get_env(:cookie) |> String.to_atom
    topology = Application.get_env :crush, :topology

    if Node.alive?(), do: Node.stop()
    node_name =
      32
      |> Utils.random_string
      |> String.to_atom

    Logger.info "[CRUSH] [APP] node: booting @ #{node_name}"

    Node.start node_name, :shortnames
    Node.set_cookie Node.self(), cookie

    children = [
      {Task.Supervisor, name: Crush.Tasker},
      Crush.Cluster,
      {Cluster.Supervisor, [topology, [name: Crush.ClusterSupervisor]]},
      CrushWeb.Telemetry,
      {Phoenix.PubSub, name: Crush.PubSub},
      CrushWeb.Endpoint,
    ]

    opts = [strategy: :one_for_one, name: Crush.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    CrushWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
