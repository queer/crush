defmodule Crush.Service do
  def ping(v \\ 1) do
    run_command "ping#{v}", {:ping, v}
  end

  def get(k) do
    run_command k, {:get, k}
  end

  def set(k, v) do
    run_command k, {:set, k, v}
  end

  def del(k) do
    run_command k, {:del, k}
  end

  defp run_command(hash_key, command) do
    idx = :riak_core_util.chash_key {"crush", hash_key}
    # TODO: Make this use more partitions for replication (configurable)
    [{index_node, _type}] = :riak_core_apl.get_primary_apl idx, 1, Crush.Service
    :riak_core_vnode_master.sync_command index_node, command, Crush.VNode_master
  end
end
