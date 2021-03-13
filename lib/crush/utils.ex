defmodule Crush.Utils do
  def random_string(length) do
    length
    |> :crypto.strong_rand_bytes
    |> Base.url_encode64(padding: false)
  end
end
