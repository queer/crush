defmodule Crush.Differ do
  alias JsonDiffEx, as: Diff

  def diff(input, prev) do
    Diff.diff input, prev
  end

  def patch(input, patch) do
    Diff.patch input, patch
  end
end
