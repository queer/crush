defmodule Crush.Differ do
  def diff(curr, prev) do
    Differ.diff curr, prev
  end

  def patch(curr, patch) do
    {:ok, patched} = Differ.patch curr, patch
    patched
  end
end
