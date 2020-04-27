defmodule CrushWeb.KVController do
  use CrushWeb, :controller
  alias Crush.Service

  def get(conn, params) do
    revision_count =
      case params["revisions"] do
        "all" ->
          :all

        nil ->
          0

        value ->
          case Integer.parse(value) do
            {integer, _} ->
              integer

            :error ->
              # TODO: Return a real error message here...
              0
          end
      end

    {:ok, _node, _partition, stored_value} = Service.get params["key"], revision_count
    case stored_value do
      {value, revisions} ->
        conn
        |> json([value | revisions])

      nil ->
        conn
        |> json([])
    end
  end

  def set(conn, params) do
    {:ok, _node, _partition, value} = Service.set params["key"], conn.body_params
    conn
    |> json(value)
  end

  def del(conn, params) do
    {:ok, _node, _partition, true} = Service.del params["key"]
    conn
    |> json(%{"deleted" => true})
  end
end
