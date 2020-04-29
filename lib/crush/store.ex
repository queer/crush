defmodule Crush.Store do
  alias Crush.Differ

  @table_name_header 'crush_'
  # TODO: Make this a config option.
  @max_revisions 8

  def init(opts) do
    partition = Keyword.get opts, :partition
    table_name = :erlang.list_to_atom(@table_name_header ++ :erlang.integer_to_list(partition))
    # Only one vnode can read or write to a table. When handoff occurs, the
    # table contents are just serialized and sent over to the receiver vnode.
    # Once this happens, the table is deleted on the current Erlang node, and so
    # it's not necessary to have concurrency here.
    table_id = :ets.new table_name, [:set, {:write_concurrency, false}, {:read_concurrency, false}]

    {table_name, table_id}
  end

  @spec get(atom(), binary(), integer() | :all, boolean()) :: term() | [term()]
  def get(table_id, k, revisions \\ 0, patch? \\ true) do
    case :ets.lookup(table_id, k) do
      [] ->
        nil

      [{_, value}] ->
        extract_value_with_revisions value, revisions, patch?
    end
  end

  defp extract_value_with_revisions(value, revision_count, patch?) do
    case value do
      {value, []} ->
        {value, []}

      {value, _} when revision_count == 0 ->
        {value, []}

      {value, patches} = res when is_list(patches) and length(patches) > 0 ->
        cond do
          patch? and revision_count == :all ->
            {value, reduce_revisions(value, patches)}

          not patch? and revision_count == :all ->
            {value, patches}

          patch? and revision_count != :all ->
            requested_patches = Enum.take patches, revision_count
            {value, reduce_revisions(value, requested_patches)}

          not patch? and revision_count != :all ->
            requested_patches = Enum.take patches, revision_count
          {value, requested_patches}
        end
    end
  end

  defp reduce_revisions(value, patches) do
    Enum.reduce patches, [], fn patch, revisions ->
      case revisions do
        [] ->
          revision = Differ.patch value, patch
          [revision]

        _ ->
          last_revision = Enum.at revisions, -1
          revision = Differ.patch last_revision, patch
          revisions ++ [revision]
      end
    end
  end

  def set(table_id, k, incoming_value) when is_map(incoming_value) do
    case get(table_id, k, :all, false) do
      nil ->
        :ets.insert table_id, {k, {incoming_value, []}}
        incoming_value

      {value, patches} = fetched ->
        next_patch = Differ.diff incoming_value, value
        patch_count =
          if length(patches) == @max_revisions do
            length(patches) - 1
          else
            length(patches)
          end

        incoming_patches = Enum.take patches, patch_count
        final_patches = [next_patch | incoming_patches]
        :ets.insert table_id, {k, {incoming_value, final_patches}}
        incoming_value
    end
  end

  # Used for handoff decode pipes only
  def set_tuple({k, v}, table_id) do
    #
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
