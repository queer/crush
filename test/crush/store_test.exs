defmodule Crush.StoreTest do
  use ExUnit.Case
  alias Crush.Store
  doctest Crush.Store

  @key "test"
  @value_1 "test_1"
  @value_2 "test_2"
  @value_3 "test_3"

  setup do
    {_table_name, table_id} = Store.init [partition: 0]
    %{table: table_id}
  end

  test "that get/set/del work", %{table: table} do
    assert nil == Store.get table, @key
    assert Store.set table, @key, @value_1
    assert {@value_1, []} == Store.get table, @key
    assert Store.set table, @key, @value_2
    assert {@value_2, []} == Store.get table, @key
    assert Store.del table, @key
  end

  test "that fetching previous revisions works", %{table: table} do
    assert Store.set table, @key, @value_1
    assert Store.set table, @key, @value_2
    assert Store.set table, @key, @value_3
    assert {@value_3, [@value_2, @value_1]} == Store.get table, @key, :all
    assert {@value_3, [@value_2]} == Store.get table, @key, 1
  end
end
