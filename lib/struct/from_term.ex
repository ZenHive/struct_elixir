defmodule Struct.FromTerm do
  @moduledoc """
  Use as a `Struct` derive to implement the following callbacks automatically

  # Example
  ```elixir
  defmodule MyStruct do
    use Struct, {
      [Struct.FromTerm],

      # Simple field
      field1: :string,

      # Field with custom type
      field2: SomeOtherStruct, # `SomeOtherStruct` must implement `Struct.FromTerm`

      # Field with custom keys
      field3: [
        :integer
        {Struct.FromTerm, keys: "custom_key"} # Specify a custom key (can also be a list of keys)
      ],
      # The keys we look for are always: [:field_name, "field_name"] ++ custom_keys
      # The example above has the following valid keys for field3: [:field3, "field3", "custom_key"]

      # Field with default value
      field4: [
        :integer,
        {Struct.FromTerm, default: 42} # Specify a default value when the keys are not found in the map
      ],

      # It is possible to use multiple options
      field5: [
        :integer,
        {Struct.FromTerm,
          keys: ["field_4", "Field4", "Field_4", 4],
          default: 42
        }
      ]
    }
  end
  ```
  """

  @typep t :: any

  @from_term_doc """
  Parses a term into the struct, validating and converting each field.

  Returns `{:ok, struct}` on success or `{:error, reason}` on failure.

  Will always return an error if the given term is not a map
  """
  @doc @from_term_doc
  @callback from_term(term()) :: {:ok, t()} | {:error, String.t()}

  @from_term_doc! """
  Parses a term into the struct, validating and converting each field.

  Returns the struct on success or raises an error on failure.

  Will always raise an error if the given term is not a map
  """
  @doc @from_term_doc!
  @callback from_term!(term()) :: t()

  @from_term_list_doc """
  Parses a list of terms into a list of structs using `from_term/1`.

  Returns `{:ok, [struct, ...]}` on success or `{:error, reason}` on failure.

  Stops at the first error
  """
  @doc @from_term_list_doc
  @callback from_term_list(term()) :: {:ok, [t()]} | {:error, String.t()}

  @from_term_list_doc! """
  Parses a list of terms into a list of structs using `from_term/1`.

  Returns `[struct, ...]` on success or raises an error on failure.

  Stops at the first error
  """
  @doc @from_term_list_doc!
  @callback from_term_list!(term()) :: [t()]

  @from_term_optional_doc """
  Parses a term into a `struct | nil` using `from_term/1`.

  Returns `{:ok, struct | nil}` or `{:error, reason}`.
  """
  @doc @from_term_optional_doc
  @callback from_term_optional(term()) :: {:ok, t() | nil} | {:error, String.t()}

  @from_term_optional_doc! """
  Parses a term into a `struct | nil` using `from_term!/1`.

  Returns `struct | nil` or raises an error on failure.
  """
  @doc @from_term_optional_doc!
  @callback from_term_optional!(term()) :: t() | nil

  @behaviour Struct.Derive

  @doc false
  @impl Struct.Derive
  def derive(fields, module, macro_env) do
    quote do
      @behaviour unquote(__MODULE__)

      @doc unquote(@from_term_doc)
      @impl unquote(__MODULE__)
      @spec from_term(term()) :: {:ok, t()} | {:error, String.t()}
      def from_term(data) when is_map(data) do
        with unquote_splicing(
               for {field, opts} <- fields do
                 quote do
                   {:ok, unquote(get_field_var(field, module))} <-
                     (
                       __value = unquote(get_value_ast(field, opts, macro_env))

                       unquote(parse_field_ast(opts, module))
                       |> case do
                         {:error, err} ->
                           {:error,
                            "Failed to parse field #{unquote(field)} of #{unquote(module)}: #{err}"}

                         ok ->
                           ok
                       end
                     )
                 end
               end
             ) do
          {
            :ok,
            %unquote(module){
              unquote_splicing(
                for {field, _opts} <- fields do
                  quote do
                    {unquote(field), unquote(get_field_var(field, module))}
                  end
                end
              )
            }
          }
        end
      end

      def from_term(value) do
        {:error, "Expected a map for #{unquote(module)} data, got: #{inspect(value)}"}
      end

      @doc unquote(@from_term_doc!)
      @impl unquote(__MODULE__)
      @spec from_term!(term()) :: t()
      def from_term!(value) do
        case from_term(value) do
          {:error, reason} -> raise "#{unquote(module)}.from_term failed: #{reason}"
          {:ok, value} -> value
        end
      end

      @doc unquote(@from_term_list_doc)
      @impl unquote(__MODULE__)
      @spec from_term_list([term()]) :: {:ok, [t()]} | {:error, String.t()}
      def from_term_list(list) when is_list(list) do
        Enum.reduce_while(list, {:ok, []}, fn elem, {:ok, acc} ->
          case from_term(elem) do
            {:ok, value} -> {:cont, {:ok, [value | acc]}}
            {:error, error} -> {:halt, {:error, error}}
          end
        end)
        |> case do
          {:error, reason} ->
            {:error, "Failed to parse list of #{unquote(module)}: #{reason}"}

          {:ok, list} ->
            {:ok, list |> Enum.reverse()}
        end
      end

      def from_term_list(value) do
        {:error,
         "Failed to parse list of #{unquote(module)}, expected a list got: #{inspect(value)}"}
      end

      @doc unquote(@from_term_list_doc!)
      @impl unquote(__MODULE__)
      @spec from_term_list!([term()]) :: [t()]
      def from_term_list!(list) do
        case from_term_list(list) do
          {:error, reason} -> raise "#{unquote(module)}.from_term_list! failed: #{reason}"
          {:ok, list} -> list
        end
      end

      @doc unquote(@from_term_optional_doc)
      @impl unquote(__MODULE__)
      @spec from_term_optional(term()) :: {:ok, t() | nil} | {:error, String.t()}
      def from_term_optional(value) do
        case value do
          nil -> {:ok, nil}
          value -> from_term(value)
        end
      end

      @doc unquote(@from_term_optional_doc!)
      @impl unquote(__MODULE__)
      @spec from_term_optional!(term()) :: t() | nil
      def from_term_optional!(value) do
        case value do
          nil -> nil
          value -> from_term!(value)
        end
      end
    end
  end

  defp get_field_var(field, module) do
    Macro.var(:"field_#{field}", module)
  end

  @doc false
  defp get_value_ast(field_name, [_type | opts], macro_env) do
    opts =
      opts
      |> Enum.find_value([], fn {module, opts} ->
        if Macro.expand(module, macro_env) == Struct.FromTerm, do: opts, else: nil
      end)

    custom_keys = opts |> Keyword.get(:keys) |> List.wrap()
    keys = default_get_value_keys(field_name) ++ custom_keys

    default_value = opts |> Keyword.get(:default)

    quote do
      unquote(keys)
      |> Enum.find_value(fn key -> data[key] end) ||
        unquote(default_value)
    end
  end

  defp get_value_ast(field_name, _type, _macro_env) do
    quote do
      unquote(default_get_value_keys(field_name))
      |> Enum.find_value(fn key -> data[key] end)
    end
  end

  defp default_get_value_keys(field_name), do: [field_name, Atom.to_string(field_name)]

  @doc false
  defp parse_field_ast([type | _opts], module), do: do_parse_field_ast(type, module)
  defp parse_field_ast(type, module), do: do_parse_field_ast(type, module)

  defp do_parse_field_ast(:integer, _module) do
    quote do
      case __value do
        value when is_integer(value) ->
          {:ok, value}

        value ->
          {:error, "Expected an integer, got: #{inspect(value)}"}
      end
    end
  end

  defp do_parse_field_ast(:neg_integer, _module) do
    quote do
      case __value do
        value when is_integer(value) and value < 0 ->
          {:ok, value}

        value ->
          {:error, "Expected a neg integer, got: #{inspect(value)}"}
      end
    end
  end

  defp do_parse_field_ast(:non_neg_integer, _module) do
    quote do
      case __value do
        value when is_integer(value) and value >= 0 ->
          {:ok, value}

        value ->
          {:error, "Expected a non neg integer, got: #{inspect(value)}"}
      end
    end
  end

  defp do_parse_field_ast(:pos_integer, _module) do
    quote do
      case __value do
        value when is_integer(value) and value > 0 ->
          {:ok, value}

        value ->
          {:error, "Expected a pos integer, got: #{inspect(value)}"}
      end
    end
  end

  defp do_parse_field_ast(:string, _module) do
    error = quote do: {:error, "Expected a string, got: #{inspect(value)}"}

    quote do
      case __value do
        value when is_binary(value) ->
          if String.valid?(value) do
            {:ok, value}
          else
            unquote(error)
          end

        value ->
          unquote(error)
      end
    end
  end

  defp do_parse_field_ast(:boolean, _module) do
    quote do
      case __value do
        value when is_boolean(value) -> {:ok, value}
        value -> {:error, "Expected a boolean, got: #{inspect(value)}"}
      end
    end
  end

  defp do_parse_field_ast(:float, _module) do
    quote do
      case __value do
        value when is_float(value) -> {:ok, value}
        value -> {:error, "Expected a float, got: #{inspect(value)}"}
      end
    end
  end

  defp do_parse_field_ast(:atom, _module) do
    quote do
      case __value do
        value when is_atom(value) -> {:ok, value}
        # Don't support generic strings to atoms, that could lead to memory leaks
        value -> {:error, "Expected an atom, got: #{inspect(value)}"}
      end
    end
  end

  defp do_parse_field_ast({:atom, expected}, _module) when is_atom(expected) do
    quote do
      cond do
        __value == unquote(expected) -> {:ok, __value}
        __value == unquote(Atom.to_string(expected)) -> {:ok, unquote(expected)}
        true -> {:error, "Expected the atom #{unquote(expected)}, got: #{inspect(__value)}"}
      end
    end
  end

  defp do_parse_field_ast(:any, _module) do
    quote do: {:ok, __value}
  end

  defp do_parse_field_ast({:tuple, sub_types}, module) do
    error =
      quote do
        {:error,
         unquote(
           "Expected #{sub_types |> Struct.get_tuple_type_ast() |> Macro.to_string()}, got: "
         ) <> inspect(__untouched_value)}
      end

    elem_var_names =
      sub_types
      |> Enum.with_index()
      |> Enum.map(fn {_type, index} -> Macro.var(:"elem_#{index}", module) end)

    elem_parsers = sub_types |> Enum.map(&do_parse_field_ast(&1, module))

    [{last_elem_var_name, last_elem_parser} | rest] =
      Enum.zip(elem_var_names, elem_parsers) |> Enum.reverse()

    last_elem_parsing_quote =
      quote do
        __value = unquote(last_elem_var_name)

        unquote(last_elem_parser)
        |> case do
          {:ok, unquote(last_elem_var_name)} -> {:ok, {unquote_splicing(elem_var_names)}}
          {:error, error} -> unquote(error)
        end
      end

    elems_parser =
      Enum.reduce(rest, last_elem_parsing_quote, fn {elem_var_name, elem_parser}, acc ->
        quote do
          __value = unquote(elem_var_name)

          unquote(elem_parser)
          |> case do
            {:error, _} -> unquote(error)
            {:ok, unquote(elem_var_name)} -> unquote(acc)
          end
        end
      end)

    quote do
      __untouched_value = __value

      case __value do
        {unquote_splicing(elem_var_names)} -> unquote(elems_parser)
        [unquote_splicing(elem_var_names)] -> unquote(elems_parser)
        _ -> unquote(error)
      end
    end
  end

  defp do_parse_field_ast({:list, type}, module) do
    quote do
      case __value do
        list when is_list(list) ->
          list
          |> Enum.reduce_while({:ok, []}, fn __value, {:ok, acc} ->
            case unquote(do_parse_field_ast(type, module)) do
              {:ok, parsed_value} ->
                {:cont, {:ok, [parsed_value | acc]}}

              {:error, error} ->
                {:halt, {:error, "Failed to parse list elem #{inspect(__value)}: #{error}"}}
            end
          end)
          |> case do
            {:error, reason} -> {:error, reason}
            {:ok, list} -> {:ok, Enum.reverse(list)}
          end

        value ->
          {:error, "Expected a list, got: #{inspect(value)}"}
      end
    end
  end

  defp do_parse_field_ast({:option, type}, module) do
    quote do
      case __value do
        nil -> {:ok, nil}
        __value -> unquote(do_parse_field_ast(type, module))
      end
    end
  end

  defp do_parse_field_ast({:one_of, sub_types}, module) do
    parse_one_of_field_ast(sub_types, Struct.get_one_of_type_ast(sub_types), module)
  end

  defp do_parse_field_ast({:elixir_type, _}, _module) do
    raise "#{__MODULE__} does not support type {:elixir_type, _}"
  end

  defp do_parse_field_ast(type_module, _module) do
    quote do: unquote(type_module).from_term(__value)
  end

  defp parse_one_of_field_ast([], type_ast, _module) do
    quote do
      {:error,
       unquote("Expected one of `#{Macro.to_string(type_ast)}`, got: ") <> inspect(__value)}
    end
  end

  defp parse_one_of_field_ast([type | rest], type_ast, module) do
    quote do
      unquote(do_parse_field_ast(type, module))
      |> case do
        {:ok, value} -> {:ok, value}
        {:error, _} -> unquote(parse_one_of_field_ast(rest, type_ast, module))
      end
    end
  end
end
