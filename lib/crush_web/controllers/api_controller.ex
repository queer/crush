defmodule CrushWeb.ApiController do
  use CrushWeb, :controller
  alias Crush.Store

  def get(conn, %{"key" => key}) do
    json conn, Store.get(key)
  end

  def set(conn, %{"key" => key}) do
    body = conn.assigns.raw_body
    IO.inspect body, label: "body"
    json conn, Store.set(key, body)
  end

  def del(conn, %{"key" => key}) do
    json conn, Store.del(key)
  end
end
