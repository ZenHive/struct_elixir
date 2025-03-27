defmodule StructTest do
  use ExUnit.Case, async: true
  doctest Struct

  defmodule Simple do
    use Struct,
      basic_type: Types.Str,
      optional_type: {:option, Types.Int},
      list_type: {:list, Types.Str}
  end

  defmodule EmptyDerives do
    use Struct, {
      [],
      [
        basic_type: [
          type: Types.Str,
          "Struct.FromTerm": "basicType"
        ]
      ]
    }
  end

  defmodule Debug do
    use Struct, {
      :debug,
      [],
      [
        basic_type: [
          type: Types.Str,
          "Struct.FromTerm": "basicType"
        ]
      ]
    }
  end

  defmodule WithDerive do
    use Struct, {
      [Struct.FromTerm],
      [
        basic_type: Types.Str
      ]
    }
  end

  defmodule WithDeriveAndCustomOption do
    use Struct, {
      [Struct.FromTerm],
      [
        basic_type: [
          type: Types.Str,
          "Struct.FromTerm": "basicType"
        ]
      ]
    }
  end

  defmodule Nested do
    use Struct, {
      [Struct.FromTerm],
      [
        basic_type: Types.Str,
        nested_type: {:option, {:list, Types.Str}},
        nested_type_custom_key: [
          type: {:option, {:list, Simple}},
          "Struct.FromTerm": "nestedTypeCustomKey"
        ]
      ]
    }
  end
end
