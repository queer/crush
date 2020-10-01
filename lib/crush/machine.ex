defmodule Crush.Machine do
  alias Crush.Store

  @behaviour RaftedValue.Data

  def new do
    :ok
  end

  def query(_, {:get, k, revisions}) do
    Store.get k, revisions
  end

  def command(_, {:set, k, v}) do
    outgoing = Store.set k, v
    {outgoing, :ok}
  end

  def command(_, {:del, k}) do
    res = Store.del k
    {res, k}
  end
end
