defmodule Crush do
  @moduledoc """
  Helper functions to make dev and debugging easier.
  """

  def ring_status do
    {:ok, ring} = :riak_core_ring_manager.get_my_ring
    :riak_core_ring.pretty_print ring, [:legend]
  end

  def join(idx) do
    "crush-#{idx}@127.0.0.1"
    |> String.to_charlist
    |> :riak_core.join
  end

  def populate(n \\ 100) do
    for i <- 1..n, do: Crush.Service.set("key_#{i}", %{"key_#{i}" => i})
  end

  def populate_async(n \\ 10_000) do
    1..n
    |> Enum.chunk_every(1)
    |> Enum.map(fn chunk ->
      Task.async fn ->
        for i <- chunk do
          Crush.Service.set "key_#{i}", %{"key_#{i}" => i}
          receive do
            {_req_id, {:ok, _node_longname, _partition, _value}} ->
              nil
          end

        end
      end
    end)
    |> Enum.map(&Task.await(&1, 3_600_000))
  end

  def populate_bench(n \\ 10_000) do
    start = :os.system_time :millisecond
    populate_async n
    finish = :os.system_time :millisecond
    time =
      finish
      |> Kernel.-(start)
      |> Kernel./(1_000)
  end
end
