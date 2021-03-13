defmodule Crush.Store do
  alias Crush.Cluster

  def get(k) do
    Cluster.read k
  end

  def set(k, v) do
    Cluster.write k, v
  end

  def del(k) do
    Cluster.delete k
  end
end
