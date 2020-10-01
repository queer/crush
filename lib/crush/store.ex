defmodule Crush.Store do
  alias Crush.Differ
  require Logger

  @table :crush
  # TODO: Make this a config option.
  @max_revisions 8

  def setup do
    :ets.new @table, [:set, :public, :named_table, {:write_concurrency, true}, {:read_concurrency, true}]
  end

  @spec get(binary(), integer() | :all, boolean()) :: term() | [term()]
  def get(k, revisions \\ 0, patch? \\ true) do
    case :ets.lookup(@table, k) do
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

      {value, patches} when is_list(patches) and length(patches) > 0 ->
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

  def set(k, incoming_value) when is_map(incoming_value) do
    case get(k, :all, false) do
      nil ->
        :ets.insert @table, {k, {incoming_value, []}}
        incoming_value

      {value, patches} ->
        next_patch = Differ.diff incoming_value, value
        patch_count =
          if length(patches) == @max_revisions do
            length(patches) - 1
          else
            length(patches)
          end

        incoming_patches = Enum.take patches, patch_count
        final_patches = [next_patch | incoming_patches]
        :ets.insert @table, {k, {incoming_value, final_patches}}
        incoming_value
    end
  end

  def del(k) do
    :ets.delete @table, k
  end
end
