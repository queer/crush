defmodule Crush.VNode do
  @behaviour :riak_core_vnode

  alias Crush.Store
  require Logger
  require Record

  Record.defrecord :fold_req_v2, :riak_core_fold_req_v2, Record.extract(:riak_core_fold_req_v2, from_lib: "riak_core/include/riak_core_vnode.hrl")

  def start_vnode(partition) do
    :riak_core_vnode_master.get_vnode_pid(partition, __MODULE__)
  end

  def init([partition]) do
    {table_name, table_id} = Store.init [partition: partition]
    state = %{
      partition: partition,
      table_name: table_name,
      table_id: table_id,
    }
    {:ok, state}
  end

  def handle_command({:ping, v}, _sender, %{partition: partition} = state) do
    {:reply, {:pong, v + 1, node(), partition}, state}
  end

  def handle_command({:set, k, v}, _sender, %{table_id: table_id, partition: partition} = state) do
    :ets.insert table_id, {k, v}
    {:reply, {:ok, node(), partition, nil}, state}
  end

  def handle_command({:get, k}, _sender, %{table_id: table_id, partition: partition} = state) do
    res = Store.get table_id, k
    {:reply, {:ok, node(), partition, res}, state}
  end

  def handle_command({:del, k}, _sender, %{table_id: table_id, partition: partition} = state) do
    res = :ets.delete table_id, k
    {:reply, {:ok, node(), partition, res}, state}
  end

  def handoff_starting(dest, %{partition: partition} = state) do
    {_tupe, {_partition_id, node_name}} = dest
    Logger.info "Starting handoff of #{partition} to: #{node_name}"
    {true, state}
  end

  def handoff_cancelled(%{partition: partition} = state) do
    Logger.info "Cancelled handoff of #{partition}"
    {:ok, state}
  end

  def handoff_finished(dest, %{partition: partition} = state) do
    {_partition_id, node_name} = dest
    Logger.info "Finished handoff of #{partition} to: #{node_name}"
    {:ok, state}
  end

  def handle_handoff_command(fold_req_v2() = fold_req, _sender, %{partition: partition, table_id: table_id} = state) do
    # These are shitty variable names but that's what they get called by riak_core...
    foldfun = fold_req_v2 fold_req, :foldfun
    acc0 = fold_req_v2 fold_req, :acc0
    out =
      Store.fold(table_id, acc0, fn {k, v}, acc_in ->
        foldfun.(k, v, acc_in)
      end)

    {:reply, out, state}
  end

  def handle_handoff_command(_request, _sender, state) do
    {:noreply, state}
  end

  def is_empty(%{table_id: table_id} = state) do
    {Store.is_empty?(table_id), state}
  end

  def terminate(_reason, _state) do
    :ok
  end

  def delete(%{table_id: table_id} = state) do
    Store.delete_table table_id
    {:ok, state}
  end

  def handle_handoff_data(data, %{table_id: table_id} = state) do
    data
    |> Store.handoff_decode
    |> Store.set_tuple(table_id)

    {:reply, :ok, state}
  end

  def encode_handoff_item(k, v) do
    Store.handoff_encode {k, v}
  end

  def handle_coverage(_req, _key_spaces, _sender, state) do
    {:stop, :not_implemented, state}
  end

  def handle_exit(_pid, _reason, state) do
    {:noreply, state}
  end

  def handle_overload_command(_, _, _) do
    :ok
  end

  def handle_overload_info(_, _idx) do
    :ok
  end
end
