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

  def populate do
    for i <- 1..100, do: Crush.Service.set("key_#{i}", i)
  end
end
