defmodule JsonRpc.ApiCreatorHelper do
  defmacro create_no_arg_methods(client, methods) do
    methods
    |> List.wrap()
    |> Enum.map(fn {:{}, _, [doc, func_name, rpc_method, response_module]} ->
      expanded_response_module = Macro.expand(response_module, __CALLER__)

      quote do
        @doc unquote(doc)
        @spec unquote(func_name)() :: Result.t(unquote(expanded_response_module).t(), any())
        def unquote(func_name)() do
          with {:ok, response} <-
                 JsonRpc.Client.WebSocket.call_without_params(
                   unquote(client),
                   unquote(rpc_method)
                 ) do
            with {:ok, result} <- response,
                 do: unquote(expanded_response_module).from_response(result)
          end
        end
      end
    end)
  end
end
