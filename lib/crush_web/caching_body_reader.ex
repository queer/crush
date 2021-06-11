defmodule CrushWeb.CachingBodyReader do
  @moduledoc false
  # https://hexdocs.pm/plug/Plug.Parsers.html#module-custom-body-reader
  @behaviour Plug

  require Logger

  def init(opts) do
    opts
  end

  def call(conn, opts) do
    {:ok, _, conn} = read_body conn, opts
    conn
  end

  def read_body(conn, opts) do
    {:ok, body, conn} = read_full_body conn, opts
    assigns =
      if conn.assigns[:raw_body] != nil and conn.assigns[:raw_body] != "" do
        conn.assigns
      else
        Map.put conn.assigns, :raw_body, body
      end

    conn = %{conn | assigns: assigns}
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
