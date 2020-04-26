defmodule Crush.Differ do
  def diff(input, prev) do
    # diff the prev to the input so that we can patch in the right direction.
    # basically, when time traveling, we need to be able to go current -> past,
    # and so the patch we store has to be able to take us from current -> past,
    # hence having to do it in that direction.
  end
end
