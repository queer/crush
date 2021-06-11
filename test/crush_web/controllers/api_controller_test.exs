defmodule CrushWeb.ApiControllerTest do
  use CrushWeb.ConnCase, async: false
  alias Crush.Store
  alias CrushWeb.Router.Helpers, as: Routes
  alias Plug.Conn

  @key "test"
  @value "value"
  @value_2 "value 2"
  @fork "test-fork"
  @default_fork Store.default_fork()

  setup do
    %{conn: build_conn()}

    on_exit fn ->
      :ok = Store.del @default_fork, @key
      :ok = Store.del @fork, @key
    end
  end

  test "that fetching a non-existent key returns empty list", %{conn: conn} do
    res =
      conn
      |> get(Routes.api_path(conn, :get, @key))
      |> json_response(200)

    assert [] == res
  end

  test "that fetching a key works", %{conn: conn} do
    res =
      conn
      |> put_req_header("content-type", "text/plain")
      |> Conn.assign(:raw_body, @value)
      |> put(Routes.api_path(conn, :set, @key))
      |> response(200)

    assert res == "{\"status\":\"ok\"}"

    res =
      conn
      |> get(Routes.api_path(conn, :get, @key))
      |> json_response(200)

    assert [:erlang.binary_to_list(@value), []] == res
  end

  test "that forking a key works", %{conn: conn} do
    conn
    |> put_req_header("content-type", "text/plain")
    |> Conn.assign(:raw_body, @value)
    |> put(Routes.api_path(conn, :set, @key))
    |> response(200)

    %{"status" => status} =
      conn
      |> put_req_header("content-type", "text/plain")
      |> post(Routes.api_path(conn, :fork, @key, @default_fork, @fork))
      |> json_response(200)

    assert "ok" == status
  end

  test "that forking and merging a key works", %{conn: conn} do
    conn
    |> put_req_header("content-type", "text/plain")
    |> Conn.assign(:raw_body, @value)
    |> put(Routes.api_path(conn, :set, @key))
    |> response(200)

    conn
    |> put_req_header("content-type", "text/plain")
    |> post(Routes.api_path(conn, :fork, @key, @default_fork, @fork))
    |> json_response(200)

    conn
    |> put_req_header("content-type", "text/plain")
    |> Conn.assign(:raw_body, @value_2)
    |> put(Routes.api_path(conn, :set, @key, @fork))
    |> response(200)

    conn
    |> put_req_header("content-type", "text/plain")
    |> post(Routes.api_path(conn, :merge, @key, @fork, @default_fork))
    |> json_response(200)

    res =
      conn
      |> put_req_header("content-type", "text/plain")
      |> get(Routes.api_path(conn, :get, @key), revisions: "all")
      |> json_response(200)

    assert ['value 2', [[["eq", 'value'], ["del", ' 2']]]] == res
  end
end
