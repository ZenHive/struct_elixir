defmodule Struct do
  @moduledoc "README.md"
             |> File.read!()
             |> String.split("<!-- Struct Module Doc Separator !-->")
             |> Enum.fetch!(1)

  @type variable_name :: atom()
  @type field_type ::
          :integer
          | :string
          | :boolean
          | :float
          | {:list, field_type()}
          | {:option, field_type()}
          | module()

  defmacro __using__({:{}, _, args}) do
    {:debug, derives, fields} = args |> List.to_tuple()

    ast = create_struct(derives, fields, __CALLER__.module)

    readable_code = ast |> Macro.to_string() |> Code.format_string!() |> IO.iodata_to_binary()
    IO.puts("use Struct Generated code for module #{__CALLER__.module}\n#{readable_code}")

    ast
  end

  defmacro __using__({derives, fields}) do
    create_struct(derives, fields, __CALLER__.module)
  end

  defmacro __using__(fields) do
    create_struct([], fields, __CALLER__.module)
  end

  defp create_struct(derives, fields, module) do
    keys = fields |> Enum.map(fn {key, _opts} -> key end)

    quote do
      @enforce_keys unquote(keys)
      defstruct unquote(keys)

      @type t :: %__MODULE__{
              unquote_splicing(Enum.map(fields, fn {field, opts} -> {field, get_type(opts)} end))
            }

      unquote_splicing(
        for derive_module <- derives do
          quote do
            (unquote_splicing(
               Macro.expand(derive_module, __ENV__)
               |> apply(:derive, [fields, module])
               |> List.wrap()
             ))
          end
        end
        |> Enum.filter(&(&1 != nil && &1 != :nop))
      )
    end
  end

  defp get_type(opts) when is_list(opts), do: opts |> Keyword.get(:type) |> do_get_type()
  defp get_type(type), do: do_get_type(type)

  defp do_get_type(:integer) do
    quote do
      integer()
    end
  end

  defp do_get_type(:string) do
    quote do
      String.t()
    end
  end

  defp do_get_type(:boolean) do
    quote do
      boolean()
    end
  end

  defp do_get_type(:float) do
    quote do
      float()
    end
  end

  defp do_get_type({:list, type}) do
    quote do
      list(unquote(get_type(type)))
    end
  end

  defp do_get_type({:option, type}) do
    quote do
      Option.t(unquote(get_type(type)))
    end
  end

  defp do_get_type(module) do
    quote do
      unquote(module).t()
    end
  end
end
