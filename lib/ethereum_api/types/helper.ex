defmodule EthereumApi.Types.Helper do
  @moduledoc false

  defmacro def_data_module(size) do
    if !is_integer(size) do
      raise ArgumentError, "Expected an integer, found #{inspect(size)}"
    end

    if size < 1 do
      raise ArgumentError, "Expected a positive integer, found #{inspect(size)}"
    end

    module_name =
      String.to_atom("Data#{size}") |> (fn arg -> Module.concat([__CALLER__.module, arg]) end).()

    # 2 hex characters per byte
    # + 2 for the 0x prefix
    expected_string_len = size * 2 + 2

    ast =
      quote do
        defmodule unquote(module_name) do
          @type t :: String.t()

          def deserialize(value) do
            with {:ok, value} <- EthereumApi.Types.Hexadecimal.deserialize(value) do
              if String.length(value) == unquote(expected_string_len) do
                {:ok, value}
              else
                {:error, "Invalid Data#{unquote(size)} len: #{inspect(value)}"}
              end
            end
          end

          def is_data?(value) do
            case deserialize(value) do
              {:ok, _} -> true
              {:error, _} -> false
            end
          end

          def is_data!(value) do
            if is_data?(value) do
              :ok
            else
              raise ArgumentError, "Expected a Data#{unquote(size)}, found #{inspect(value)}"
            end
          end
        end
      end

    readable_code = ast |> Macro.to_string() |> Code.format_string!() |> IO.iodata_to_binary()
    IO.puts("Generated code for module #{module_name}\n#{readable_code}")
    ast
  end
end
