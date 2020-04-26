defmodule Crush.Supervisor do
  use Supervisor

  def start_link(_) do
    res = Supervisor.start_link __MODULE__, [], name: :crush_sup
    case res do
      {:ok, pid} ->
        :ok = :riak_core.register [vnode_module: Crush.VNode]
        :ok = :riak_core_node_watcher.service_up Crush.Service, self()
        {:ok, pid}

      _ ->
        raise "Couldn't start supervisor: #{inspect res, pretty: true}"
    end
  end

  def init(_) do
    children = [
      worker(:riak_core_vnode_master, [Crush.VNode], id: Crush.VNode_master_worker)
    ]
    supervise children, strategy: :one_for_one, max_restarts: 5, max_seconds: 10
  end
end
