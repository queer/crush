defmodule Crush.StoreTest do
  use ExUnit.Case, async: false
  alias Crush.Store
  alias Crush.Store.{Ancestor, Item}

  @key "test"
  @value "test 1"
  @value_2 "test 2"

  @fork "test-fork"
  @default_fork Store.default_fork()

  setup do
    on_exit fn ->
      :ok = Store.del @default_fork, @key
      :ok = Store.del @fork, @key
    end
  end

  test "it works" do
    assert @value == Store.set @default_fork, @key, @value
    assert %Item{
      value: @value,
      patches: [],
      rev: 0,
    } == Store.get @default_fork, @key, :all
  end

  test "fetching revisions works" do
    Store.set @default_fork, @key, @value
    Store.set @default_fork, @key, @value_2

    assert %Item{
      value: @value_2,
      patches: [
        [eq: "test ", del: "2", ins: "1"]
      ],
      rev: 1,
    } == Store.get @default_fork, @key, :all, false
  end

  test "patching revisions works" do
    Store.set @default_fork, @key, @value
    Store.set @default_fork, @key, @value_2
    Store.set @default_fork, @key, @value

    assert %Item{
      value: @value,
      patches: [@value_2, @value],
      rev: 2,
    } == Store.get @default_fork, @key, :all, true
  end

  test "forking works" do
    Store.set @default_fork, @key, @value

    item = Store.get @default_fork, @key
    assert :ok == Store.fork @key, @fork, item

    default = @default_fork
    assert match? %Item{
      value: @value,
      fork: @fork,
      ancestors: [%Ancestor{fork: ^default, rev: 0}],
    }, Store.get(@fork, @key)
  end

  test "merging works" do
    Store.set @default_fork, @key, @value

    item = Store.get @default_fork, @key
    assert :ok == Store.fork @key, @fork, item

    Store.set @fork, @key, @value_2

    assert :ok == Store.merge @key, @fork, @default_fork

    item = Store.get @default_fork, @key, :all, false
    default = @default_fork
    assert match? %Item{
      fork: ^default,
      ancestors: [%Ancestor{fork: @fork, rev: 1}],
      patches: [_],
      value: @value_2,
      rev: 1,
    }, item
  end
end
