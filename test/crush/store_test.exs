defmodule Crush.StoreTest do
  use ExUnit.Case, async: false
  alias Crush.Store
  doctest Crush.Store

  @key "test"
  @value_1 %{"key" => "test_1"}
  @value_2 %{"key" => "test_2"}
  @value_3 %{"key" => "test_3"}

  setup do
    Store.init nil
    :ok
  end

  test "that get/set/del work" do
    assert nil == Store.get @key
    refute Store.set(@key, @value_1) == nil
    assert {@value_1, []} == Store.get @key
    refute Store.set(@key, @value_2) == nil
    assert {@value_2, []} == Store.get @key
    refute Store.del(@key) == nil
  end

  test "that fetching previous revisions works" do
    assert Store.set @key, @value_1
    assert Store.set @key, @value_2
    assert Store.set @key, @value_3
    assert {@value_3, [@value_2, @value_1]} == Store.get(@key, :all)
    assert {@value_3, [@value_2]} == Store.get(@key, 1)
  end
end
