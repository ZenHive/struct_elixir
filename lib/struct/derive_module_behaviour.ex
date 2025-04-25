defmodule Struct.DeriveModuleBehaviour do
  @moduledoc """
  Defines the callback that must be implemented by a module to be able to use it as a struct derive.
  """

  @doc """
  This function will be called exactly once for each struct that derives your behaviour.
  It is expected to return the AST of the code your behaviour generates.

  Args:
  - field: A list of the struct field
    Example:
    ```elixir
    [
      field1: :integer,
      field2: SomeOtherModule,
      field3: [
        type: :integer, # Type MUST always be present in the list
        some_custom_option_for_a_behaviour: 42 # Can be any type
      ]
    ]
    ```
  - module: The module that is currently defining a struct

  Must return either an AST or a list of ASTs
  (The list may also contain `nil` and `:nop`, those value will be ignored)
  """
  @callback derive(
              fields :: [
                {
                  Struct.variable_name(),
                  Struct.field_type()
                  | [
                      # type MUST be included in the list
                      {:type, Struct.field_type()}
                      | {atom(), any()}
                    ]
                }
              ],
              caller_module :: module()
            ) :: Macro.t() | [Macro.t() | nil | :nop]
end
