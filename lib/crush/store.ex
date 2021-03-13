defmodule Crush.Store do
  alias Crush.{Cluster, Differ}

  @max_revisions 8

  def get(key, revisions \\ 0, patch? \\ true) do
    case Cluster.read(key) do
      nil -> nil
      value -> extract_value_with_revisions value, revisions, patch?
    end
  end

  defp extract_value_with_revisions(value, revision_count, patch?) do
    case value do
      {value, []} ->
        # Value-only, return no revs
        {value, []}

      {value, _} when revision_count == 0 ->
        # No revs wanted
        {value, []}

      {value, patches} when is_list(patches) and length(patches) > 0 ->
        # Have patches, return as many as needed, patching as needed
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

  def set(key, incoming_value) do
    case get(key, :all, false) do
      nil ->
        Cluster.write key, {incoming_value, []}
        incoming_value

      {value, patches} ->
        # Diff required to move from stored value to incoming value
        next_patch = Differ.diff incoming_value, value

        # Take the maximum number of patches we can
        patch_count = length patches
        patch_count =
          if patch_count == @max_revisions do
            patch_count - 1
          else
            patch_count
          end

        # Write patches and new value
        incoming_patches = Enum.take patches, patch_count
        Cluster.write key, {incoming_value, [next_patch | incoming_patches]}
        incoming_value
    end
  end

  def del(key) do
    Cluster.delete key
    :ok
  end
end
