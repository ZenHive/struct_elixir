defmodule Struct.FromTerm do
  def derive(fields, caller_module) do
    quote do
      @spec from_term(term()) :: Result.t(t(), String.t())
      def from_term(data) when is_map(data) do
        with unquote_splicing(
               for {field, opts} <- fields do
                 quote do
                   {:ok, unquote(get_field_var(field, __MODULE__))} <-
                     unquote(Struct.FromTerm.get_value_ast(field, opts))
                     |> unquote(Struct.FromTerm.parse_field_ast(opts))
                     |> Result.map_err(
                       &"Failed to parse field #{unquote(field)} of #{unquote(caller_module)}: #{&1}"
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

      def from_term!(value) do
        from_term(value)
        |> Result.unwrap!()
      end

      @spec from_term_list([term()]) :: Result.t([t()], String.t())
      def from_term_list(list) when is_list(list) do
        Result.try_reduce(list, [], fn elem, acc ->
          from_term(elem)
          |> Result.map(&[&1 | acc])
        end)
        |> Result.map(&Enum.reverse/1)
        |> Result.map_err(&"Failed to parse list of #{unquote(caller_module)}: #{&1}")
      end

      def from_term_list(value) do
        {:error,
         "Failed to parse list of #{unquote(caller_module)}, expected a list got #{inspect(value)}"}
      end

      @spec from_term_list!([term()]) :: [t()]
      def from_term_list!(list) do
        from_term_list(list)
        |> Result.unwrap!()
      end

      @spec from_term_optional(term()) :: Result.t(Option.t(t()), String.t())
      def from_term_optional(value), do: Option.map(value, &from_term/1)

      @spec from_term_optional!(term()) :: Option.t(t())
      def from_term_optional!(value), do: Option.map(value, &from_term!/1)
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
    do_parse_field(type)
  end

  def parse_field_ast(type), do: do_parse_field(type)

  defp do_parse_field({:option, type}) do
    quote do
      case do
        nil -> {:ok, nil}
        value -> value |> unquote(do_parse_field(type))
      end
    end
  end

  defp do_parse_field({:list, type}) do
    quote do
      case do
        value when is_list(value) ->
          Result.try_reduce(value, [], fn value, acc ->
            value
            |> unquote(do_parse_field(type))
            |> Result.map(&[&1 | acc])
            |> Result.map_err(&"Failed to parse list elem #{inspect(value)}: #{&1}")
          end)
          |> Result.map(&Enum.reverse/1)

        value ->
          quote do: {:error, "Expected a list, got #{inspect(value)}"}
      end
    end
  end

  defp do_parse_field(type) do
    quote do: unquote(type).from_term()
  end
end
