defmodule CrushWeb.CachingBodyReader do
  @moduledoc false
  # https://hexdocs.pm/plug/Plug.Parsers.html#module-custom-body-reader

  def read_body(conn, opts) do
    {:ok, body, conn} = read_full_body conn, opts
    conn = update_in conn.assigns[:raw_body], fn _ -> body end
    {:ok, body, conn}
  end

  defp read_full_body(conn, opts, body \\ "") do
    case Plug.Conn.read_body(conn, opts) do
      {:ok, req_body, conn} ->
        {:ok, body <> req_body, conn}

      {:more, partial_body, conn} ->
        read_full_body conn, opts, body <> partial_body
    end
  end
end