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
                     {:ok, unquote(Macro.var(field, __MODULE__))} <-
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
                      {unquote(field), unquote(Macro.var(field, __MODULE__))}
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

  def get_value(map, field_name, opts) when is_list(opts) do
    opts
    |> Keyword.get(:"Struct.FromTerm")
    |> case do
      nil -> map[field_name]
      keys -> keys |> List.wrap() |> Enum.find_value(nil, fn key -> map[key] end)
    end
  end

  def get_value(map, field_name, _type) do
    map[field_name]
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
    Enum.reduce_while(value, {:ok, []}, fn elem, {:ok, acc} ->
      case do_parse_field(elem, type) do
        {:ok, elem} ->
          {:cont, {:ok, [elem | acc]}}

        {:error, error} ->
          {:halt, {:error, "Failed to parse list elem #{inspect(elem)}: #{error}"}}
      end
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
