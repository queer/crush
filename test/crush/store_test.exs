defmodule Crush.StoreTest do
  use ExUnit.Case, async: false
  alias Crush.Store

  @key "test"
  @value "test 1"
  @value_2 "test 2"

  setup do
    on_exit fn ->
      :ok == Store.del Store.default_fork(), @key
    end
  end

  test "it works" do
    assert @value == Store.set Store.default_fork(), @key, @value
    assert %Store.Item{
      value: @value, patches: []
    } == Store.get Store.default_fork(), @key, :all
  end

  test "fetching revisions works" do
    assert @value == Store.set Store.default_fork(), @key, @value
    assert @value_2 == Store.set Store.default_fork(), @key, @value_2
    assert %Store.Item{
      value: @value_2,
      patches: [
        [eq: "test ", del: "2", ins: "1"]
      ],
    } == Store.get Store.default_fork(), @key, :all, false
  end

  test "patching revisions works" do
    assert @value == Store.set Store.default_fork(), @key, @value
    assert @value_2 == Store.set Store.default_fork(), @key, @value_2
    assert @value == Store.set Store.default_fork(), @key, @value
    assert %Store.Item{
      value: @value,
      patches: [@value_2, @value],
    } == Store.get Store.default_fork(), @key, :all, true
  end
end
