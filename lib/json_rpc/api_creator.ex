defmodule JsonRpc.ApiCreator do
  defmacro __using__({client, methods}, debug \\ false) do
    module = __CALLER__.module

    methods
    |> List.wrap()
    |> Enum.map(&generate_ast(&1, client, module))
    |> print_debug_code(module, debug)
  end

  defp generate_ast({:%{}, _, opts}, client, module) do
    %{
      method: method,
      doc: doc,
      response_type: response_type,
      response_parser: response_parser
    } = opts = Enum.into(opts, %{})

    args = Map.get(opts, :args, []) |> List.wrap()
    args_spec = Enum.map(args, fn {arg, type} -> quote do: unquote(arg) :: unquote(type) end)
    args = Enum.map(args, fn {arg, _type} -> arg end)
    args_transformer! = get_args_transformer!(args, opts, method)

    func_name = method |> to_snake_case() |> String.to_atom()
    func_path = Module.concat(module, func_name)
    response_module = Module.concat([module, Response, to_camel_case(method)])

    quote do
      defmodule unquote(response_module) do
        @moduledoc "Defines the type returned by #{unquote(func_path)}()"
        unquote(generate_response_type_ast(response_type, method))
      end

      @doc unquote(doc)
      @spec unquote(func_name)(unquote_splicing(args_spec)) ::
              Result.t(unquote(response_module).t(), any())
      def unquote(func_name)(unquote_splicing(args)) do
        unquote(
          generate_function_body_ast(
            args,
            client,
            method,
            response_parser,
            args_transformer!
          )
        )
      end
    end
  end

  defp get_args_transformer!(args, opts, method) do
    case args do
      [] ->
        :nop

      [_ | _] ->
        Map.get(opts, :args_transformer!) ||
          throw("Missing key :args_transformer! for method #{method}")
    end
  end

  defp generate_response_type_ast({:type_alias, t}, _method),
    do: quote(do: @type(t :: unquote(t)))

  defp generate_response_type_ast({:json_struct, t}, _method),
    do: quote(do: use(JsonStruct, unquote(t)))

  defp generate_response_type_ast({:struct, t}, _method), do: quote(do: defstruct(unquote(t)))

  defp generate_response_type_ast(_invalid, method),
    do: throw("Invalid response_type for method #{method}")

  defp generate_function_body_ast(
         [],
         client,
         method,
         response_parser,
         _args_transformer!
       ) do
    quote do
      with {:ok, response} <-
             JsonRpc.Client.WebSocket.call_without_params(unquote(client), unquote(method)),
           {:ok, result} <- response,
           do: unquote(response_parser).(result)
    end
  end

  defp generate_function_body_ast(
         args,
         client,
         method,
         response_parser,
         args_transformer!
       ) do
    quote do
      with {:ok, response} <-
             JsonRpc.Client.WebSocket.call_with_params(
               unquote(client),
               unquote(method),
               unquote(args_transformer!).(unquote_splicing(args)) |> List.wrap()
             ),
           {:ok, result} <- response,
           do: unquote(response_parser).(result)
    end
  end

  defp print_debug_code(ast, module, debug) do
    if debug do
      readable_code = ast |> Macro.to_string() |> Code.format_string!() |> IO.iodata_to_binary()
      IO.puts("Generated code for module #{module} #{readable_code}")
    end

    ast
  end

  defp to_snake_case(str) do
    str
    |> String.replace(
      # Find a lowercase letter followed by an uppercase letter
      ~r/([a-z])([A-Z])/,
      # Replace with the lowercase letter, an underscore, and the uppercase letter
      "\\1_\\2"
    )
    |> String.downcase()
  end

  defp to_camel_case(str) do
    str
    # Because String.capitalize() lowercases all chars that aren't the first (ie: fooBar -> Foobar)
    |> to_snake_case()
    # Split by underscores
    |> String.split(~r/[_]/)
    # Capitalize each word
    |> Enum.map(&String.capitalize/1)
    # Join them back together
    |> Enum.join("")
  end
end
