defmodule StructTest do
  use ExUnit.Case, async: true
  doctest Struct

  defmodule Empty do
    use Struct, []
  end

  defmodule Simple do
    use Struct,
      basic_type: :string,
      optional_type: {:option, :integer},
      list_type: {:list, :string},
      elixir_type: {:elixir_type, map()}
  end

  defmodule EmptyDerives do
    use Struct, {
      [],
      basic_type: [:string, {Struct.FromTerm, keys: "basicType"}]
    }
  end

  defmodule Debug do
    use Struct, {
      :debug,
      [],
      basic_type: :string,
      one_of_type: {:one_of, [:string, :integer, :float]},
      tuple_type: {:tuple, [:integer, :float, :string]}
    }
  end

  defmodule WithDerive do
    use Struct, {
      [Struct.FromTerm],
      basic_type: :string
    }
  end

  defmodule WithDeriveAndCustomOption do
    use Struct, {
      [Struct.FromTerm],
      basic_type: [
        :string,
        {Struct.FromTerm, keys: "basicType"}
      ]
    }
  end

  defmodule Nested do
    use Struct, {
      [Struct.FromTerm],
      basic_type: :string,
      nested_type: {:option, {:list, :string}},
      nested_type_custom_key: [
        {:option, {:list, WithDerive}},
        {Struct.FromTerm, keys: "nestedTypeCustomKey"}
      ]
    }
  end
end
