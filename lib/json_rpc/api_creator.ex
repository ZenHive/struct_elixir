defmodule JsonRpc.ApiCreator do
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

  defmacro __using__({client, methods}) do
    ast =
      methods
      |> List.wrap()
      # |> IO.inspect()
      |> Enum.map(fn {:%{}, _, opts} ->
        %{
          method: method,
          doc: doc,
          response_type: response_type,
          response_parser: response_parser
        } = opts = Enum.into(opts, %{})

        args =
          Map.get(opts, :args) ||
            []
            |> List.wrap()
            |> IO.inspect()

        args_spec =
          args
          |> Enum.map(fn {arg, type} ->
            quote do: unquote(arg) :: unquote(type)
          end)

        args = args |> Enum.map(fn {arg, _type} -> arg end)

        args_checker! =
          case args do
            [] ->
              :nop

            [_ | _] ->
              Map.get(opts, :args_checker!) ||
                throw("Missing key :args_checker! for method #{method}")
          end

        func_name = method |> to_snake_case() |> String.to_atom()
        func_path = Module.concat(__CALLER__.module, func_name)
        response_module = Module.concat(__CALLER__.module, to_camel_case(method))

        quote do
          defmodule unquote(response_module) do
            @moduledoc "Defines the type returned by #{unquote(func_path)}()"

            unquote(
              case response_type do
                {:type_alias, t} ->
                  quote do: @type(t :: unquote(t))

                {:json_struct, t} ->
                  quote do: use(JsonStruct, unquote(t))

                {:struct, t} ->
                  # TODO add typespec for struct
                  quote do: defstruct(unquote(t))

                _ ->
                  throw("Invalid response_type for method #{method}: #{inspect(response_type)}")
              end
            )
          end

          @doc unquote(doc)
          @spec unquote(func_name)(unquote_splicing(args_spec)) ::
                  Result.t(unquote(response_module).t(), any())
          def unquote(func_name)(unquote_splicing(args)) do
            unquote(
              if Enum.empty?(args) do
                quote do
                  with {:ok, response} <-
                         JsonRpc.Client.WebSocket.call_without_params(
                           unquote(client),
                           unquote(method)
                         ),
                       {:ok, result} <- response,
                       do: unquote(response_parser).(result)
                end
              else
                quote do
                  unquote(args_checker!).(unquote_splicing(args))

                  with {:ok, response} <-
                         JsonRpc.Client.WebSocket.call_with_params(
                           unquote(client),
                           unquote(method),
                           unquote(args)
                         ),
                       {:ok, result} <- response,
                       do: unquote(response_parser).(result)
                end
              end
            )
          end
        end
      end)

    readable_code = ast |> Macro.to_string() |> Code.format_string!() |> IO.iodata_to_binary()
    IO.puts("Generated code for module #{__CALLER__.module} #{readable_code}")
    ast
  end
end
