defmodule Crush.Service do
  def ping(v \\ 1) do
    run_command "ping#{v}", {:ping, v}
  end

  def get(k, revisions \\ 0) do
    run_command k, {:get, k, revisions}
  end

  def set(k, v) when is_map(v) do
    run_command k, {:set, k, v}
  end

  def del(k) do
    run_command k, {:del, k}
  end

  defp run_command(hash_key, command) do
    idx = :riak_core_util.chash_key {"crush", hash_key}
    # TODO: Make this use more partitions for replication (configurable)
    # TODO: WHY is this faster than the async :command/4?
    # https://github.com/queer/crush/issues/5
    [{index_node, _type}] = :riak_core_apl.get_primary_apl idx, 1, Crush.Service
    :riak_core_vnode_master.sync_spawn_command index_node, command, Crush.VNode_master

    # preflist = :riak_core_apl.get_apl idx, 1, Crush.Service
    # request_id = :erlang.monotonic_time |> :erlang.phash2
    # sender = {:raw, request_id, self()}
    # :riak_core_vnode_master.command preflist, command, sender, Crush.VNode_master
  end
end
