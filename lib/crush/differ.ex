defmodule Crush.Differ do
  def diff(input, prev) do
    Diff.diff input, prev
  end

  def patch(input, patch, joiner) do
    Diff.patch input, patch, joiner
  end
end
