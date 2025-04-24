defmodule Struct.TypesTest do
  use ExUnit.Case, async: true
  doctest Struct.Types
  doctest Struct.Types.Int
  doctest Struct.Types.Str
  doctest Struct.Types.Bool
  doctest Struct.Types.Float
end
