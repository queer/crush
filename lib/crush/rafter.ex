defmodule Crush.Rafter do
  @moduledoc """
  A helper module to make interacting with Raft easier
  """

  alias Crush.Store

  @doc """
  `{value, [revisions]}`
  """
  @spec get(binary(), :all | integer()) :: nil | {term(), term()}
  def get(key, revisions \\ 0) do
    Store.get key, revisions
  end


  @doc """
  `value`
  """
  @spec set(binary(), term()) :: term()
  def set(key, value) do
    Store.set key, value
  end

  @doc """
  `true`
  """
  @spec del(binary()) :: true
  def del(key) do
    Store.del key
  end
end
