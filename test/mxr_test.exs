defmodule MxrTest do
  use ExUnit.Case
  doctest Mxr

  test "greets the world" do
    assert Mxr.hello() == :world
  end
end
