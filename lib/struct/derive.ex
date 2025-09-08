defmodule Struct.Derive do
  @moduledoc """
  Defines the callback that must be implemented by a module to be able to use it as a struct derive.
  """

  @doc """
  This function will be called exactly once for each struct that derives your behaviour.
  It is expected to return the AST of the code your behaviour generates.

  Example:
  ```elixir
  # For the following struct definition
  defmodule MyStruct do
    use Struct, {
      [Struct.FromTerm],
      field1: :integer,
      field2: SomeOtherModule,
      field3: [
        :integer,
        {Struct.FormTerm, default: 42}
      ]
    }
  end

  # Arguments passed to the derive function will be:
  fields = [
    field1: :integer,
    field2: SomeOtherModule,
    field3: [
      :integer,
      {Struct.FormTerm, default: 42}
    ]
  ]
  module = MyStruct
  ```

  Must return either an AST or a list of ASTs
  (The list may also contain `nil` and `:nop`, those value will be ignored)
  """
  @callback derive(
              fields :: [
                {
                  Struct.variable_name(),
                  Struct.field_type()
                  | [
                      # First elem is Struct.field_type(), the rest are options {module(), any()}
                      Struct.field_type()
                      | {module(), any()}
                    ]
                }
              ],
              module(),
              Macro.Env.t()
            ) :: Macro.t() | [Macro.t() | nil | :nop]
end
