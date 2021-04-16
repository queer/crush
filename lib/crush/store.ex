defmodule Crush.Store do
  use TypedStruct
  alias Crush.{Cluster, Differ}

  @default_fork "default"

  typedstruct module: Item do
    field :value, binary()
    field :patches, [binary()]
    field :fork, String.t(), default: "default"
    field :ancestors, [Ancestor.t()], default: []
    field :rev, non_neg_integer(), default: 0
  end

  typedstruct module: Ancestor do
    field :fork, String.t()
    field :rev, non_neg_integer()
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
        :ok = Cluster.write to_key(fork, key), %Item{value: incoming_value, patches: []}
        incoming_value

      %Item{value: value, patches: patches, rev: rev} = item ->
        # Diff required to move from stored value to incoming value
        next_patch = Differ.diff incoming_value, value

        # Write all patches and new value
        :ok = Cluster.write to_key(fork, key), %{
            item
            | value: incoming_value,
              patches: [next_patch | patches],
              rev: rev + 1,
          }

        incoming_value
    end
  end

  @spec fork(String.t(), String.t(), __MODULE__.Item.t()) :: :ok
  def fork(key, target, %Item{fork: fork, ancestors: ancestors, rev: rev} = item) do
    # Move the item to the target fork, and prepend previous fork to ancestors
    new_item = %{item | fork: target, ancestors: [%Ancestor{fork: fork, rev: rev} | ancestors]}
    Cluster.write to_key(target, key), new_item
  end

  @spec merge(String.t(), String.t(), String.t()) :: :ok
  def merge(key, source_fork, target_fork) do
    %Item{
      value: source_value,
      fork: source_fork,
      rev: source_rev,
    } = get source_fork, key, :all, false

    %Item{
      value: target_value,
      fork: ^target_fork,
      patches: patches,
      ancestors: ancestors,
      rev: target_rev,
    } = target = get target_fork, key, :all, false

    next_patch = Differ.diff source_value, target_value
    merged_item = %{
      target
      | value: source_value,
        patches: [next_patch | patches],
        ancestors: [%Ancestor{fork: source_fork, rev: source_rev} | ancestors],
        rev: target_rev + 1,
    }

    Cluster.write to_key(target_fork, key), merged_item
  end

  @spec del(String.t(), String.t()) :: :ok
  def del(fork, key) do
    Cluster.delete to_key(fork, key)
    :ok
  end

  defp to_key(fork, key), do: fork <> ":" <> key

  @spec default_fork() :: String.t()
  def default_fork, do: @default_fork
end
