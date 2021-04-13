defmodule Crush.Store do
  use TypedStruct
  alias Crush.{Cluster, Differ}

  @default_fork "default"

  typedstruct module: Item do
    field :value, binary()
    field :patches, [binary()]
    field :fork, String.t(), default: "default"
    field :ancestors, [String.t()], default: []
  end

  @spec get(String.t(), String.t(), :all | non_neg_integer(), boolean()) :: nil | Crush.Store.Item.t()
  def get(fork, key, revisions \\ 0, patch? \\ true) do
    case Cluster.read(to_key(fork, key)) do
      nil -> nil
      value -> extract_value_with_revisions value, revisions, patch?
    end
  end

  defp extract_value_with_revisions(%Item{patches: []} = item, _, _) do
    item
  end

  defp extract_value_with_revisions(%Item{} = item, 0, _) do
    %{item | patches: []}
  end

  defp extract_value_with_revisions(%Item{value: value, patches: patches} = item, :all, true) do
    %{item | patches: reduce_revisions(value, patches)}
  end

  defp extract_value_with_revisions(%Item{} = item, :all, false) do
    item
  end

  defp extract_value_with_revisions(%Item{value: value, patches: patches} = item, revs, true) do
    requested_patches = Enum.take patches, revs
    %{item | patches: reduce_revisions(value, requested_patches)}
  end

  defp extract_value_with_revisions(%Item{patches: patches} = item, revs, false) do
    requested_patches = Enum.take patches, revs
    %{item | patches: requested_patches}
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

  @spec set(String.t(), String.t(), binary()) :: binary()
  def set(fork, key, incoming_value) do
    case get(fork, key, :all, false) do
      nil ->
        Cluster.write to_key(fork, key), %Item{value: incoming_value, patches: []}
        incoming_value

      %Item{value: value, patches: patches} ->
        # Diff required to move from stored value to incoming value
        next_patch = Differ.diff incoming_value, value

        # Write all patches and new value
        Cluster.write to_key(fork, key), %Item{value: incoming_value, patches: [next_patch | patches]}
        incoming_value
    end
  end

  @spec del(String.t(), String.t()) :: :ok
  def del(fork, key) do
    Cluster.delete to_key(fork, key)
    :ok
  end

  defp to_key(fork, key), do: fork <> ":" <> key

  def default_fork, do: @default_fork
end
