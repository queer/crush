defmodule Crush do
  @moduledoc """
  Crush keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
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
