defmodule CrushWeb.ApiController do
  use CrushWeb, :controller
  alias Crush.Store
  alias Crush.Store.Item

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
      %Item{value: value, patches: patches} ->
        json conn, [value | patches_to_json(patches)]

      nil -> json conn, []
    end
  end

  defp patches_to_json(patches) do
    Enum.map patches, fn
      rev when is_list(rev) ->
        Enum.map rev, fn
          part when is_tuple(part) -> Tuple.to_list part
          part -> part
        end

      rev -> rev
    end
  end

  def key_info(conn, %{"key" => key}) do
    revision_count =
      case Store.get(key, :all, false) do
        %Item{value: _,  patches: patches} -> length(patches)
        nil -> 0
      end

    info = %{
      key: key,
      revision_count: revision_count,
    }

    json conn, info
  end

  def set(conn, %{"key" => key}) do
    body = conn.assigns.raw_body
    json conn, Store.set(key, body)
  end

  def del(conn, %{"key" => key}) do
    json conn, Store.del(key)
  end
end
