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

      # Field with custom keys
      field2: [
        type: SomeOtherStruct, # `SomeOtherStruct` must implement `Struct.FromTerm`
        "Struct.FromTerm": [keys: "custom_key"] # Specify a custom key (can also be a list of keys)
      ],
      # The keys we look for are always: [:field_name, "field_name"] ++ custom_keys
      # ie: example above has the following valid keys for field2: [:field2, "field2", "custom_key"]

      # Field with default value
      field3: [
        type: :integer,
        "Struct.FromTerm": [default: 42] # Specify a default value when the keys are not found in the map
      ]

      # It is possible to use multiple options
      field4: [
        type: :integer,
        "Struct.FromTerm": [
          keys: ["field_4", "Field4", "Field_4", 4],
          default: 42
        ]
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
  Parses a list of terms into a list of structs using from_term/1.
  Returns `{:ok, [struct, ...]}` on success or `{:error, reason}` on failure.

  Stops at the first error
  """
  @doc @from_term_list_doc
  @callback from_term_list(term()) :: {:ok, [t()]} | {:error, String.t()}

  @from_term_list_doc! """
  Parses a list of terms into a list of structs using from_term/1.
  Returns `[struct, ...]` on success or raises an error on failure.

  Stops at the first error
  """
  @doc @from_term_list_doc!
  @callback from_term_list!(term()) :: [t()]

  @from_term_optional_doc """
  Parses a term into a `struct | nil` using from_term/1.
  Returns `{:ok, struct | nil}` or `{:error, reason}`.
  """
  @doc @from_term_optional_doc
  @callback from_term_optional(term()) :: {:ok, t() | nil} | {:error, String.t()}

  @from_term_optional_doc! """
  Parses a term into a `struct | nil` using from_term!/1.
  Returns `struct | nil` or raises an error on failure.
  """
  @doc @from_term_optional_doc!
  @callback from_term_optional!(term()) :: t() | nil

  @behaviour Struct.DeriveModuleBehaviour

  @doc false
  @impl Struct.DeriveModuleBehaviour
  def derive(fields, caller_module) do
    self_module = __MODULE__

    quote do
      @behaviour unquote(self_module)

      @doc unquote(@from_term_doc)
      @impl unquote(self_module)
      @spec from_term(term()) :: {:ok, t()} | {:error, String.t()}
      def from_term(data) when is_map(data) do
        with unquote_splicing(
               for {field, opts} <- fields do
                 quote do
                   {:ok, unquote(get_field_var(field, __MODULE__))} <-
                     (
                       __value = unquote(Struct.FromTerm.get_value_ast(field, opts))

                       unquote(Struct.FromTerm.parse_field_ast(opts))
                       |> case do
                         {:error, err} ->
                           {:error,
                            "Failed to parse field #{unquote(field)} of #{unquote(caller_module)}: #{err}"}

                         ok ->
                           ok
                       end
                     )
                 end
               end
             ) do
          {
            :ok,
            %unquote(caller_module){
              unquote_splicing(
                for {field, _opts} <- fields do
                  quote do
                    {unquote(field), unquote(get_field_var(field, __MODULE__))}
                  end
                end
              )
            }
          }
        end
      end

      def from_term(value) do
        {:error, "Expected a map for #{unquote(caller_module)} data, got #{inspect(value)}"}
      end

      @doc unquote(@from_term_doc!)
      @impl unquote(self_module)
      @spec from_term!(term()) :: t()
      def from_term!(value) do
        case from_term(value) do
          {:error, reason} -> raise "#{unquote(caller_module)}.from_term failed: #{reason}"
          {:ok, value} -> value
        end
      end

      @doc unquote(@from_term_list_doc)
      @impl unquote(self_module)
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
            {:error, "Failed to parse list of #{unquote(caller_module)}: #{reason}"}

          {:ok, list} ->
            {:ok, list |> Enum.reverse()}
        end
      end

      def from_term_list(value) do
        {:error,
         "Failed to parse list of #{unquote(caller_module)}, expected a list got #{inspect(value)}"}
      end

      @doc unquote(@from_term_list_doc!)
      @impl unquote(self_module)
      @spec from_term_list!([term()]) :: [t()]
      def from_term_list!(list) do
        case from_term_list(list) do
          {:error, reason} -> raise "#{unquote(caller_module)}.from_term_list! failed: #{reason}"
          {:ok, list} -> list
        end
      end

      @doc unquote(@from_term_optional_doc)
      @impl unquote(self_module)
      @spec from_term_optional(term()) :: {:ok, t() | nil} | {:error, String.t()}
      def from_term_optional(value) do
        case value do
          nil -> {:ok, nil}
          value -> from_term(value)
        end
      end

      @doc unquote(@from_term_optional_doc!)
      @impl unquote(self_module)
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
  def get_value_ast(field_name, opts) when is_list(opts) do
    quote do
      value = data[unquote(field_name)]

      unquote_splicing(
        if from_term_opts = Keyword.get(opts, :"Struct.FromTerm") do
          [
            if keys = Keyword.get(from_term_opts, :keys) do
              case keys do
                keys when is_list(keys) ->
                  quote do
                    value = value || unquote(keys) |> Enum.find_value(fn key -> data[key] end)
                  end

                key ->
                  quote do: value = value || data[unquote(key)]
              end
            end,
            if default = Keyword.get(from_term_opts, :default) do
              # TODO Check that default has the right type at compile time
              quote do: value = value || unquote(default)
            end
          ]
        end
        |> Enum.filter(&(&1 != nil))
      )
    end
  end

  def get_value_ast(field_name, _type) do
    string_key = Atom.to_string(field_name)
    quote do: data[unquote(field_name)] || data[unquote(string_key)]
  end

  @doc false
  def parse_field_ast(opts) when is_list(opts) do
    type = opts |> Keyword.get(:type)
    do_parse_field_ast(type)
  end

  def parse_field_ast(type), do: do_parse_field_ast(type)

  defp do_parse_field_ast(:integer) do
    quote do
      case __value do
        value when is_integer(value) ->
          {:ok, value}

        value ->
          {:error, "Expected an integer, got #{inspect(value)}"}
      end
    end
  end

  defp do_parse_field_ast(:neg_integer) do
    quote do
      case __value do
        value when is_integer(value) and value < 0 ->
          {:ok, value}

        value ->
          {:error, "Expected a neg integer, got #{inspect(value)}"}
      end
    end
  end

  defp do_parse_field_ast(:non_neg_integer) do
    quote do
      case __value do
        value when is_integer(value) and value >= 0 ->
          {:ok, value}

        value ->
          {:error, "Expected a non neg integer, got #{inspect(value)}"}
      end
    end
  end

  defp do_parse_field_ast(:pos_integer) do
    quote do
      case __value do
        value when is_integer(value) and value > 0 ->
          {:ok, value}

        value ->
          {:error, "Expected a pos integer, got #{inspect(value)}"}
      end
    end
  end

  defp do_parse_field_ast(:string) do
    error = quote do: {:error, "Expected a string, got #{inspect(value)}"}

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

  defp do_parse_field_ast(:boolean) do
    quote do
      case __value do
        value when is_boolean(value) -> {:ok, value}
        value -> {:error, "Expected a boolean, got #{inspect(value)}"}
      end
    end
  end

  defp do_parse_field_ast(:float) do
    quote do
      case __value do
        value when is_float(value) -> {:ok, value}
        value -> {:error, "Expected a float, got #{inspect(value)}"}
      end
    end
  end

  defp do_parse_field_ast(:atom) do
    quote do
      case __value do
        value when is_atom(value) -> {:ok, value}
        # Don't support generic strings to atoms, that could lead to memory leaks
        value -> {:error, "Expected an atom, got #{inspect(value)}"}
      end
    end
  end

  defp do_parse_field_ast({:atom, expected}) when is_atom(expected) do
    quote do
      cond do
        __value == unquote(expected) -> {:ok, __value}
        __value == unquote(Atom.to_string(expected)) -> {:ok, unquote(expected)}
        true -> {:error, "Expected the atom #{unquote(expected)}, got #{inspect(__value)}"}
      end
    end
  end

  defp do_parse_field_ast(:any) do
    quote do: {:ok, __value}
  end

  defp do_parse_field_ast({:list, type}) do
    quote do
      case __value do
        list when is_list(list) ->
          list
          |> Enum.reduce_while({:ok, []}, fn __value, {:ok, acc} ->
            case unquote(do_parse_field_ast(type)) do
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
          {:error, "Expected a list, got #{inspect(value)}"}
      end
    end
  end

  defp do_parse_field_ast({:option, type}) do
    quote do
      case __value do
        nil -> {:ok, nil}
        __value -> unquote(do_parse_field_ast(type))
      end
    end
  end

  defp do_parse_field_ast({:one_of, types}) do
    parse_one_of_field_ast(types, Struct.get_one_of_type_ast(types))
  end

  defp do_parse_field_ast({:elixir_type, _}) do
    raise "#{__MODULE__} does not support type {:elixir_type, _}"
  end

  defp do_parse_field_ast(module) do
    quote do: unquote(module).from_term(__value)
  end

  defp parse_one_of_field_ast([], types_ast) do
    quote do
      {:error,
       "Expected one of `#{unquote(Macro.to_string(types_ast))}`, found: #{inspect(__value)}"}
    end
  end

  defp parse_one_of_field_ast([type | rest], types_ast) do
    quote do
      unquote(do_parse_field_ast(type))
      |> case do
        {:ok, value} -> {:ok, value}
        {:error, _} -> unquote(parse_one_of_field_ast(rest, types_ast))
      end
    end
  end
end
