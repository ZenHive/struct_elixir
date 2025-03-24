defmodule Types do
  @moduledoc """
  `Types` is a module that provides a set of modules used by JsonStruct to validate and deserialize
  see `JsonStruct` for more information.
  """

  defmodule Int do
    @type t :: integer()

    def deserialize(value) when is_integer(value), do: {:ok, value}
    def deserialize(value), do: {:error, "Invalid integer (#{inspect(value)})"}
  end

  defmodule Str do
    @type t :: String.t()

    def deserialize(value) when is_binary(value) do
      if Elixir.String.valid?(value) do
        {:ok, value}
      else
        {:error, "Invalid string (#{inspect(value)})"}
      end
    end

    def deserialize(value) do
      {:error, "Invalid string (#{inspect(value)})"}
    end
  end

  defmodule Bool do
    @type t :: boolean()

    def deserialize(value) when value in [true, false], do: {:ok, value}
    def deserialize(value), do: {:error, "Invalid boolean (#{inspect(value)})"}
  end

  defmodule Float do
    @type t :: float()

    def deserialize(value) when is_float(value), do: {:ok, value}
    def deserialize(value), do: {:error, "Invalid float (#{inspect(value)})"}
  end
end
