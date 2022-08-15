defmodule ExecutorTest do
  use ExUnit.Case
  doctest Executor

  test "greets the world" do
    assert Executor.hello() == :world
  end
end
