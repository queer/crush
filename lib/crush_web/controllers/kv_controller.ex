defmodule CrushWeb.KVController do
  use CrushWeb, :controller
  alias Crush.Raft

  # TODO: ALL of these need to just blocking await recv

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

    case Raft.get(params["key"], revision_count) do
      {:ok, {value, revisions}} ->
        conn
        |> json([value | revisions])

      {:ok, nil} ->
        conn
        |> json(nil)
    end
  end

  def set(conn, params) do
    {:ok, value} = Raft.set params["key"], conn.body_params
    conn
    |> json(value)
  end

  def del(conn, params) do
    Raft.del params["key"]
    conn
    |> json(%{"deleted" => true})
  end
end
