defmodule Types do
  @moduledoc """
  `Types` is a module that provides a set of modules used by JsonStruct to validate and deserialize
  see `JsonStruct` for more information.
  """

  defmodule Int do
    @type t :: integer()

    def from_term(value) when is_integer(value), do: {:ok, value}
    def from_term(value), do: {:error, "Expected integer, got #{inspect(value)}"}

    def from_term!(value) do
      case from_term(value) do
        {:ok, value} -> value
        {:error, _} -> raise ArgumentError, "Expected integer, got #{inspect(value)}"
      end
    end
  end

  defmodule Str do
    @type t :: String.t()

    def from_term(value) when is_binary(value) do
      if Elixir.String.valid?(value) do
        {:ok, value}
      else
        {:error, "Expected string, got #{inspect(value)}"}
      end
    end

    def from_term(value) do
      {:error, "Expected string, got #{inspect(value)}"}
    end

    def from_term!(value) do
      case from_term(value) do
        {:ok, value} -> value
        {:error, _} -> raise ArgumentError, "Expected string, got #{inspect(value)}"
      end
    end
  end

  defmodule Bool do
    @type t :: boolean()

    def from_term(value) when value in [true, false], do: {:ok, value}
    def from_term(value), do: {:error, "Expected boolean, got #{inspect(value)}"}

    def from_term!(value) do
      case from_term(value) do
        {:ok, value} -> value
        {:error, _} -> raise ArgumentError, "Expected boolean, got #{inspect(value)}"
      end
    end
  end

  defmodule Float do
    @type t :: float()

    def from_term(value) when is_float(value), do: {:ok, value}
    def from_term(value), do: {:error, "Expected float, got #{inspect(value)}"}

    def from_term!(value) do
      case from_term(value) do
        {:ok, value} -> value
        {:error, _} -> raise ArgumentError, "Expected float, got #{inspect(value)}"
      end
    end
  end
end
