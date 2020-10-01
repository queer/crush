defmodule Crush.Raft do
  use GenServer
  alias Crush.Machine
  require Logger

  @interval 100
  @group_name :crush
  # TODO: Configurable
  @group_size 3

  def start_link(_) do
    GenServer.start_link __MODULE__, [], name: __MODULE__
  end

  def init(_) do
    activate()
    state = node_list()

    Process.send_after self(), :diff, @interval

    {:ok, state}
  end

  def handle_info(:diff, state) do
    unless state == node_list() do
      Logger.info "[CRUSH] [CLUSTER] Reactivating Raft zone due to cluster topology changes"
      activate()
    end
    Process.send_after self(), :diff, @interval
    {:noreply, node_list()}
  end

  def activate do
    # TODO: Make this configurable
    RaftFleet.activate "zone1"
    fn ->
      ensure_exists()
    end
    |> Task.async
    |> Task.await
  end

  def get(k, revisions) do
    RaftFleet.query @group_name, {:get, k, revisions}
  end

  def set(k, v) do
    res = RaftFleet.command @group_name, {:set, k, v}
    IO.inspect res, pretty: true
  end

  def del(k) do
    RaftFleet.command @group_name, {:del, k}
  end

  defp ensure_exists do
    Logger.debug "Creating new consensus group..."
    config = RaftedValue.make_config Machine
    # TODO: Make queue group size configurable
    case RaftFleet.add_consensus_group(@group_name, @group_size, config) do
      :ok ->
        Logger.debug "Group created as #{@group_name}!"
        @group_name = await_leader @group_size
        :ok

      {:error, :already_added} ->
        Logger.debug "Group already exists!"
        @group_name = await_leader @group_size
        :ok

      {:error, :no_leader} ->
        Logger.debug "Group has no leader!"
        @group_name = await_leader @group_size
        :ok

      # {:error, :cleanup_ongoing} ->
        # TODO: ??????

      err ->
        raise "Unknown crush raft group start result: #{inspect err}"
    end
  end

  defp await_leader(member_count) do
    me = self()
    ref = make_ref()
    spawn_link fn ->
      :timer.sleep 100
      send me, ref
    end
    receive do
      ^ref ->
        # Check if we have a leader. If we do, yay! If we don't, keep blocking.
        if has_leader?(member_count) do
          @group_name
        else
          await_leader member_count
        end
    end
  end

  defp has_leader?(member_count) do
    case RaftFleet.whereis_leader(@group_name) do
      pid when is_pid(pid) ->
        %{leader: leader, members: members} = RaftedValue.status pid
        leader != nil and length(members) <= member_count

      nil ->
        false
    end
  end

  defp node_list do
    [Node.self() | Node.list()]
  end
end
