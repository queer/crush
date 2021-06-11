defmodule Crush.Persister do
  @moduledoc """
  Persistence for the DeltaCrdt that backs crush.

  A bit counter-intuitively, this does **not** store individual key-value
  pairs, but rather stores the state of the *entire* crdt.
  """

  @behaviour DeltaCrdt.Storage

  @type storage_format() :: {node_id :: term(), sequence_number :: integer(), crdt_state :: term()}

  @impl DeltaCrdt.Storage
  @spec read(term()) :: storage_format() | nil
  def read(name) do
    name
    |> file_name
    |> File.exists?
    |> if do
      data = File.read! file_name(name)
      {^name, storage_format} = :erlang.binary_to_term data
      storage_format
    else
      nil
    end
  end

  @impl DeltaCrdt.Storage
  @spec write(term(), storage_format()) :: :ok
  def write(name, storage_format) do
    data = :erlang.term_to_binary {name, storage_format}
    File.mkdir_p! "./#{dir_name()}"
    File.write! file_name(name), data
    :ok
  end

  defp dir_name, do: "#{Node.self()}"
  defp file_name(name), do: "./#{Node.self()}/#{name_to_key(name)}.crush"
  defp name_to_key(nil), do: "store"
  defp name_to_key(name) when is_binary(name), do: name
  defp name_to_key(name) when is_atom(name), do: Atom.to_string name
  defp name_to_key(name), do: :erlang.term_to_binary name
end
