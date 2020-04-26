defmodule Crush.Store do
  @table_name_header 'crush_'

  def init(opts) do
    partition = Keyword.get opts, :partition
    table_name = :erlang.list_to_atom(@table_name_header ++ :erlang.integer_to_list(partition))
    # Only one vnode can read or write to a table. When handoff occurs, the
    # table contents are just serialized and sent over to the receiver vnode.
    # Once this happens, the table is deleted on the current Erlan node, and so
    # it's not necessary to have concurrency here.
    table_id = :ets.new table_name, [:set, {:write_concurrency, false}, {:read_concurrency, false}]

    {table_name, table_id}
  end

  def get(table_id, k) do
    case :ets.lookup(table_id, k) do
      [] ->
        nil

      [{_, value}] ->
        value
    end
  end

  def set(table_id, k, v) do
    :ets.insert table_id, {k, v}
  end

  # Used for handoff decode pipes only
  def set_tuple({k, v}, table_id) do
    :ets.insert table_id, {k, v}
  end

  def del(table_id, k) do
    :ets.delete table_id, k
  end

  def is_empty?(table_id) do
    :ets.first(table_id) == :"$end_of_table"
  end

  def delete_table(table_id) do
    :ets.delete table_id
  end

  def handoff_encode(term) do
    :erlang.term_to_binary term
  end

  def handoff_decode(binary) do
    :erlang.binary_to_term binary
  end

  def fold(table_id, acc, f) do
    :ets.foldl(f, acc, table_id)
  end
end
