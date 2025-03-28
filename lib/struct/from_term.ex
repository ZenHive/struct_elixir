defmodule Struct.FromTerm do
  defmacro __using__({:{}, _, args}) do
    {fields, caller_module, debug?} = args |> List.to_tuple()

    ast =
      quote do
        @spec from_term(term()) :: Result.t(t(), String.t())
        def from_term(data) when is_map(data) do
          with unquote_splicing(
                 for {field, opts} <- fields do
                   quote do
                     {:ok, unquote(get_field_var(field, __MODULE__))} <-
                       data
                       |> Struct.FromTerm.get_value(unquote(field), unquote(opts))
                       |> Struct.FromTerm.parse_field(unquote(opts))
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

        def from_term_optional(value), do: Option.map(value, &from_term/1)
      end

    if debug? do
      readable_code =
        ast |> Macro.to_string() |> Code.format_string!() |> IO.iodata_to_binary()

      IO.puts(
        "use Struct.FromTerm generated code for module #{__CALLER__.module}\n#{readable_code}"
      )
    end

    ast
  end

  defp get_field_var(field, module) do
    Macro.var(:"field_#{field}", module)
  end

  def get_value(map, field_name, opts) when is_list(opts) do
    map[field_name]
    |> Option.unwrap_or_else(fn ->
      Keyword.get(opts, :"Struct.FromTerm")
      |> Option.map(fn from_term_opts ->
        from_term_opts
        |> Keyword.get(:keys)
        |> Option.map(fn keys ->
          keys |> List.wrap() |> Enum.find_value(fn key -> map[key] end)
        end)
        |> Option.unwrap_or_else(fn ->
          Keyword.get(from_term_opts, :default)
        end)
      end)
    end)
  end

  def get_value(map, field_name, _type) do
    map[field_name] || map[Atom.to_string(field_name)]
  end

  def parse_field(value, opts) when is_list(opts) do
    type = opts |> Keyword.get(:type)
    do_parse_field(value, type)
  end

  def parse_field(value, type), do: do_parse_field(value, type)

  defp do_parse_field(value, {:option, type}) do
    case value do
      nil -> {:ok, nil}
      value -> do_parse_field(value, type)
    end
  end

  defp do_parse_field(value, {:list, type}) when is_list(value) do
    Result.try_reduce(value, [], fn elem, acc ->
      do_parse_field(elem, type)
      |> Result.map(&[&1 | acc])
      |> Result.map_err(&"Failed to parse list elem #{inspect(elem)}: #{&1}")
    end)
    |> Result.map(&Enum.reverse/1)
  end

  defp do_parse_field(value, {:list, _type}) do
    {:error, "Expected a list, got #{inspect(value)}"}
  end

  defp do_parse_field(value, type) do
    type.from_term(value)
  end
end
