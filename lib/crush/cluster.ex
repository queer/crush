defmodule Crush.Cluster do
  use GenServer
  require Logger

  @table :cluster_crdt

  def start_link(_) do
    GenServer.start_link __MODULE__, 0, name: __MODULE__
  end

  def init(_) do
    :net_kernel.monitor_nodes true
    Logger.debug "[CRUSH] [CLUSTER] boot: node: monitor up"
    {:ok, crdt} = DeltaCrdt.start_link DeltaCrdt.AWLWWMap, storage_module: Crush.Persister
    :ets.new @table, [:named_table, :public, :set, read_concurrency: true]
    :ets.insert @table, {:crdt, crdt}
    {:ok, crdt}
  end

  def handle_info({msg, _}, crdt) when msg in [:nodeup, :nodedown] do
    Logger.info "[CRUSH] [CLUSTER] topology: crdt: neighbours updating..."
    neighbours =
      Node.list()
      |> Enum.map(fn node ->
        Task.Supervisor.async {Crush.Tasker, node}, fn ->
          __MODULE__.get_crdt()
        end
      end)
      |> Enum.map(&Task.await/1)

    :ok = DeltaCrdt.set_neighbours crdt, neighbours
    Logger.info "[CRUSH] [CLUSTER] topology: crdt: neighbours updated"
    {:noreply, crdt}
  end

  @spec get_crdt :: pid()
  def get_crdt do
    :ok = spin_on_table()
    [{:crdt, crdt}] = :ets.lookup @table, :crdt
    crdt
  end

  defp spin_on_table do
    case :ets.whereis(@table) do
      :undefined ->
        # This should effectively never really spin
        :timer.sleep 5
        spin_on_table()

      _ -> :ok
    end
  end

  @spec write(String.t(), any()) :: :ok
  def write(k, v) do
    DeltaCrdt.mutate get_crdt(), :add, [k, v]
  end

  @spec read(String.t()) :: any()
  def read(k) do
    get_crdt() |> DeltaCrdt.read |> Map.get(k)
  end

  @spec delete(String.t()) :: :ok
  def delete(k) do
    DeltaCrdt.mutate get_crdt(), :remove, [k]
  end

  @spec keys() :: [binary()]
  def keys do
    get_crdt() |> DeltaCrdt.read |> Map.keys
  end
end
