defmodule Crush.Store do
  @table :crush

  # TODO: Make this a config option.
  @max_revisions 8

  def init(_) do
    unless :ets.whereis(@table) == :undefined do
      # Test helper
      :ets.delete @table
    end

    :ets.new @table, [:public, :set, :named_table, {:write_concurrency, false}, {:read_concurrency, false}]

    :ok
  end

  @spec get(binary(), integer() | :all) :: nil | {term(), [] | [term()]}
  def get(k, revisions \\ 0) do
    case :ets.lookup(@table, k) do
      [] ->
        nil

      [{_, value}] ->
        extract_value_with_revisions value, revisions
    end
  end

  defp extract_value_with_revisions(value, revision_count) do
    case value do
      {value, []} ->
        {value, []}

      {value, _} when revision_count == 0 ->
        {value, []}

      {value, revisions} when is_list(revisions) and length(revisions) > 0 ->
        cond do
          revision_count == :all ->
            {value, revisions}

          revision_count != :all ->
            requested_patches = Enum.take revisions, revision_count
            {value, requested_patches}
        end
    end
  end

  @spec set(binary(), term()) :: term()
  def set(k, incoming_value) when is_map(incoming_value) do
    case get(k, :all) do
      nil ->
        :ets.insert @table, {k, {incoming_value, []}}
        incoming_value

      {value, revisions} ->
        patch_count =
          if length(revisions) == @max_revisions do
            length(revisions) - 1
          else
            length(revisions)
          end

        incoming_patches = Enum.take revisions, patch_count
        final_patches = [value | incoming_patches]
        :ets.insert @table, {k, {incoming_value, final_patches}}
        incoming_value
    end
  end

  @spec del(binary()) :: true
  def del(k) do
    :ets.delete @table, k
  end
end
