defmodule CrushWeb.KVController do
  use CrushWeb, :controller
  alias Crush.Rafter

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

    stored_value = Rafter.get params["key"], revision_count
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
    value = Rafter.set params["key"], conn.body_params
    conn
    |> json(value)
  end

  def del(conn, params) do
    _res = Rafter.del params["key"]
    conn
    |> json(%{"deleted" => true})
  end
end
