defmodule Crush.Store do
  @moduledoc """
  Crush's data store.

  Data is currently stored in a DeltaCRDT AWLWWMap. Data is stored in the map
  as a tuple `{current_value, patches}`, where the current value is any binary,
  and the patches are a list of diff operations required to transform said
  binary into its previous state.
  """

  use TypedStruct
  alias Crush.{Cluster, Differ}

  typedstruct module: Item do
    field :value, binary()
    field :patches, [binary()]
  end

  def get(key, revisions \\ 0, patch? \\ true) do
    case Cluster.read(key) do
      nil -> nil
      value -> extract_value_with_revisions value, revisions, patch?
    end
  end

  defp extract_value_with_revisions(%Item{value: value, patches: []}, _, _), do: {value, []}
  defp extract_value_with_revisions(%Item{value: value, patches: _}, 0, _), do: {value, []}
  defp extract_value_with_revisions(%Item{value: value, patches: patches}, :all, true) do
    {value, reduce_revisions(value, patches)}
  end
  defp extract_value_with_revisions(%Item{value: value, patches: patches}, :all, false) do
    {value, patches}
  end
  defp extract_value_with_revisions(%Item{value: value, patches: patches}, revs, true) do
    requested_patches = Enum.take patches, revs
        {value, reduce_revisions(value, requested_patches)}
  end
  defp extract_value_with_revisions(%Item{value: value, patches: patches}, revs, false) do
    requested_patches = Enum.take patches, revs
    {value, requested_patches}
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

        # Write all patches and new value
        Cluster.write key, {incoming_value, [next_patch | patches]}
        incoming_value
    end
  end

  def del(key) do
    Cluster.delete key
    :ok
  end
end
