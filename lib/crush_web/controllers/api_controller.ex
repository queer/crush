defmodule CrushWeb.ApiController do
  use CrushWeb, :controller
  alias Crush.{Cluster, Store}
  alias Crush.Store.Item

  def get(conn, %{"key" => key} = params) do
    fork = params["fork"] || Store.default_fork()
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

    case Store.get(fork, key, rev_count, patch?) do
      %Item{value: value, patches: patches} ->
        json conn, [value_to_json(value), patches_to_json(patches)]

      nil -> json conn, []
    end
  end

  defp value_to_json(part) when is_tuple(part) do
    part
    |> Tuple.to_list
    |> Enum.map(fn
      x when is_binary(x) -> :erlang.binary_to_list x
      x when is_atom(x) -> Atom.to_string x
      x -> value_to_json x
    end)
  end
  defp value_to_json(part) when is_list(part) do
    Enum.map part, fn
      x when is_binary(x) -> :erlang.binary_to_list x
      x when is_atom(x) -> Atom.to_string x
      x -> value_to_json x
    end
  end
  defp value_to_json(part) when is_binary(part), do: :erlang.binary_to_list part
  defp value_to_json(part), do: part

  defp patches_to_json([]), do: []
  defp patches_to_json(patches) do
    Enum.map patches, &value_to_json/1
  end

  def set(conn, %{"key" => key} = params) do
    fork = params["fork"] || Store.default_fork()
    body = conn.assigns.raw_body
    Store.set(fork, key, body)
    json conn, %{status: :ok}
  end

  def del(conn, %{"key" => key} = params) do
    fork = params["fork"] || Store.default_fork()
    :ok = Store.del(fork, key)
    json conn, %{status: :ok}
  end

  def key_info(conn, %{"key" => key} = params) do
    fork = params["fork"] || Store.default_fork()
    revision_count =
      case Store.get(fork, key, :all, false) do
        %Item{value: _,  patches: patches} -> length(patches)
        nil -> 0
      end

    info = %{
      key: key,
      revision_count: revision_count,
    }

    json conn, info
  end

  def fork(conn, %{"key" => key, "fork" => fork, "target" => target}) do
    item =
      case Store.get(fork, key, :all, false) do
        %Item{} = item -> item
        _ -> nil
      end

    if item do
      :ok = Store.fork key, target, item
      json conn, %{status: :ok}
    else
      conn
      |> put_status(:not_found)
      |> json(%{status: :error, error: :not_found})
    end
  end

  def merge(conn, %{"key" => key, "fork" => fork, "target" => target}) do
    source? =
      case Store.get(fork, key, 0, false) do
        %Item{} -> true
        _ -> false
      end

    target? =
      case Store.get(target, key, :all, false) do
        %Item{} -> true
        _ -> false
      end

    cond do
      not source? ->
        conn
        |> put_status(404)
        |> json(%{status: :error, error: :source_not_found})

      not target? ->
        conn
        |> put_status(404)
        |> json(%{status: :error, error: :target_not_found})

      true ->
        :ok = Store.merge key, fork, target
        json conn, %{status: :ok}
    end
  end

  def keys(conn, %{"prefix" => prefix} = params) do
    prefix = (params["fork"] || Store.default_fork()) <> ":" <> prefix
    keys =
      Enum.filter(Cluster.keys(), fn key ->
        String.starts_with? key, prefix
      end)

    json conn, keys
  end

  def keys(conn, _) do
    json conn, Cluster.keys()
  end
end
