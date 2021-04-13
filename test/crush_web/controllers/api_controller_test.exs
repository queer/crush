defmodule CrushWeb.ApiControllerTest do
  use CrushWeb.ConnCase, async: false
  alias Crush.Store
  alias CrushWeb.Router.Helpers, as: Routes
  alias Plug.Conn

  @key "test"
  @value "value"

  setup do
    %{conn: build_conn()}

    on_exit fn ->
      :ok == Store.del @key
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

    assert res == inspect(@value)
  end
end
