defmodule JsonRpc.ApiCreator do
  defmacro __using__({:{}, _, [:debug, client, methods]}) do
    methods
    |> List.wrap()
    |> Enum.map(&generate_ast(&1, client, __CALLER__.module))
    |> print_debug_code(__CALLER__.module)
  end

  defmacro __using__({client, methods}) do
    methods
    |> List.wrap()
    |> Enum.map(&generate_ast(&1, client, __CALLER__.module))
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
    response_type_name = String.to_atom("#{func_name}_response") |> Macro.var(module)

    quote do
      @type unquote(response_type_name) :: unquote(response_type)

      @doc unquote(doc)
      @spec unquote(func_name)(unquote_splicing(args_spec)) ::
              Result.t(unquote(response_type_name), any())
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

  defp print_debug_code(ast, module) do
    readable_code = ast |> Macro.to_string() |> Code.format_string!() |> IO.iodata_to_binary()
    IO.puts("Generated code for module #{module} #{readable_code}")

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
end
