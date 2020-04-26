defmodule Crush.VNode do
  @behaviour :riak_core_vnode

  require Logger

  require Record
  Record.defrecord :fold_req_v2, :riak_core_fold_req_v2, Record.extract(:riak_core_fold_req_v2, from_lib: "riak_core/include/riak_core_vnode.hrl")

  def start_vnode(partition) do
    :riak_core_vnode_master.get_vnode_pid(partition, __MODULE__)
  end

  def init([partition]) do
    table_name = :erlang.list_to_atom 'crush_' ++ :erlang.integer_to_list(partition)
    table_id = :ets.new table_name, [:set, {:write_concurrency, false}, {:read_concurrency, false}]
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
    res =
      case :ets.lookup(table_id, k) do
        [] ->
          nil

        [{_, value}] ->
          value
      end

    {:reply, {:ok, node(), partition, res}, state}
  end

  def handle_command({:del, k}, _sender, %{table_id: table_id, partition: partition} = state) do
    :ets.delete table_id, k
    {:reply, {:ok, node(), partition, nil}, state}
  end

  def handoff_starting(dest, %{partition: partition} = state) do
    Logger.info "Starting handoff of #{partition} to: #{inspect dest}"
    {true, state}
  end

  def handoff_cancelled(%{partition: partition} = state) do
    Logger.info "Cancelled handoff of #{partition}"
    {:ok, state}
  end

  def handoff_finished(dest, %{partition: partition} = state) do
    Logger.info "Finished handoff of #{partition} to: #{inspect dest}"
    {:ok, state}
  end

  def handle_handoff_command(fold_req_v2() = fold_req, _sender, %{partition: partition, table_id: table_id} = state) do
    foldfun = fold_req_v2 fold_req, :foldfun
    acc0 = fold_req_v2 fold_req, :acc0
    out =
      :ets.foldl(fn {k, v}, acc_in ->
        foldfun.(k, v, acc_in)
      end, acc0, table_id)

    {:reply, out, state}
  end

  def handle_handoff_command(_request, _sender, state) do
    {:noreply, state}
  end

  def is_empty(%{table_id: table_id} = state) do
    empty? = :ets.first(table_id) == :"$end_of_table"
    {empty?, state}
  end

  def terminate(_reason, _state) do
    :ok
  end

  def delete(%{table_id: table_id} = state) do
    :ets.delete table_id
    {:ok, state}
  end

  def handle_handoff_data(data, %{table_id: table_id} = state) do
    {k, v} = :erlang.binary_to_term data
    :ets.insert table_id, {k, v}
    {:reply, :ok, state}
  end

  def encode_handoff_item(k, v) do
    :erlang.term_to_binary {k, v}
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
