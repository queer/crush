defmodule CrushWeb.ApiController do
  use CrushWeb, :controller
  alias Crush.Store

  def get(conn, %{"key" => key} = params) do
    rev_count =
      case params["revisions"] do
        "all" -> :all
        nil -> 0
        value ->
          case Integer.parse(value) do
            {integer, _} -> integer
            :error -> 0
          end
      end

    patch? = params["patch"] == "true"

    case Store.get(key, rev_count, patch?) do
      {value, revisions} ->
        IO.inspect [value | revisions_to_json(revisions)], label: "out"
        json conn, [value | revisions_to_json(revisions)]
      nil -> json conn, []
    end
  end

  defp revisions_to_json(revisions) do
    Enum.map revisions, fn
      rev when is_list(rev) ->
        Enum.map rev, fn
          part when is_tuple(part) -> Tuple.to_list part
          part -> part
        end

      rev -> rev
    end
  end

  def set(conn, %{"key" => key}) do
    body = conn.assigns.raw_body
    json conn, Store.set(key, body)
  end

  def del(conn, %{"key" => key}) do
    json conn, Store.del(key)
  end
end
