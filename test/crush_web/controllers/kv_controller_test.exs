defmodule CrushWeb.KVControllerTest do
  use CrushWeb.ConnCase
  alias CrushWeb.KVController
  doctest CrushWeb.KVController

  @key "test"
  @value_1 %{"test" => "test"}
  @value_2 %{"test" => "test 2"}
  @value_3 %{"test" => "test 3", "test-3" => "3rd test"}

  setup do
    Crush.Service.del @key
    :ok
  end

  test "that get/set/del works", %{conn: conn} do
    res = get_value conn, @key
    assert [] == res

    res = set_value conn, @key, @value_1
    assert @value_1 == res

    res = delete_value conn, @key
    assert %{"deleted" => true} == res
  end

  test "that getting revisions works", %{conn: conn} do
    assert @value_1 == set_value conn, @key, @value_1
    assert @value_2 == set_value conn, @key, @value_2
    assert @value_3 == set_value conn, @key, @value_3
    res = get_value conn, @key, "all"
    assert [@value_3, @value_2, @value_1] == res
  end

  defp get_value(conn, key, revisions \\ 0) do
    res =
      conn
      |> get(Routes.kv_path(conn, :get, key, revisions: revisions))

    res.resp_body
    |> Jason.decode!
  end

  defp set_value(conn, key, value) do
    res =
      conn
      |> put_req_header("content-type", "application/json; charset=utf-8")
      |> put(Routes.kv_path(conn, :set, key), Jason.encode!(value))

    res.resp_body
    |> Jason.decode!
  end

  defp delete_value(conn, key) do
    res =
      conn
      |> delete(Routes.kv_path(conn, :del, key))

    res.resp_body
    |> Jason.decode!
  end
end
