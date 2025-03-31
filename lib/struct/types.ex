defmodule Struct.Types do
  @moduledoc """
  `Types` is a module that provides a set of modules used by the `Struct` module
  see `Struct` for more information.
  """

  defmodule Int do
    @moduledoc """
    Type module for handling integer values.
    """
    @type t :: integer()

    @doc """
    Validates that a value is an integer.

    ## Examples

        iex> Struct.Types.Int.from_term(42)
        {:ok, 42}

        iex> Struct.Types.Int.from_term("42")
        {:error, "Expected integer, got \\\"42\\\""}
    """
    def from_term(value) when is_integer(value), do: {:ok, value}
    def from_term(value), do: {:error, "Expected integer, got #{inspect(value)}"}

    @doc """
    Validates that a value is an integer, raising an error if validation fails.

    ## Examples

        iex> Struct.Types.Int.from_term!(42)
        42

        iex> Struct.Types.Int.from_term!("42")
        ** (ArgumentError) Expected integer, got "42"
    """
    def from_term!(value) do
      case from_term(value) do
        {:ok, value} -> value
        {:error, _} -> raise ArgumentError, "Expected integer, got #{inspect(value)}"
      end
    end
  end

  defmodule Str do
    @moduledoc """
    Type module for handling string values.
    """
    @type t :: String.t()

    @doc """
    Validates that a value is a valid string.

    ## Examples

        iex> Struct.Types.Str.from_term("hello")
        {:ok, "hello"}

        iex> Struct.Types.Str.from_term(42)
        {:error, "Expected string, got 42"}
    """
    def from_term(value) when is_binary(value) do
      if Elixir.String.valid?(value) do
        {:ok, value}
      else
        {:error, "Invalid string, got #{inspect(value)}"}
      end
    end

    def from_term(value) do
      {:error, "Expected string, got #{inspect(value)}"}
    end

    @doc """
    Validates that a value is a valid string, raising an error if validation fails.

    ## Examples

        iex> Struct.Types.Str.from_term!("hello")
        "hello"

        iex> Struct.Types.Str.from_term!(42)
        ** (ArgumentError) Expected string, got 42
    """
    def from_term!(value) do
      case from_term(value) do
        {:ok, value} -> value
        {:error, _} -> raise ArgumentError, "Expected string, got #{inspect(value)}"
      end
    end
  end

  defmodule Bool do
    @moduledoc """
    Type module for handling boolean values.
    """
    @type t :: boolean()

    @doc """
    Validates that a value is a boolean.

    ## Examples

        iex> Struct.Types.Bool.from_term(true)
        {:ok, true}

        iex> Struct.Types.Bool.from_term("true")
        {:error, "Expected boolean, got \\\"true\\\""}
    """
    def from_term(value) when value in [true, false], do: {:ok, value}
    def from_term(value), do: {:error, "Expected boolean, got #{inspect(value)}"}

    @doc """
    Validates that a value is a boolean, raising an error if validation fails.

    ## Examples

        iex> Struct.Types.Bool.from_term!(true)
        true

        iex> Struct.Types.Bool.from_term!("true")
        ** (ArgumentError) Expected boolean, got "true"
    """
    def from_term!(value) do
      case from_term(value) do
        {:ok, value} -> value
        {:error, _} -> raise ArgumentError, "Expected boolean, got #{inspect(value)}"
      end
    end
  end

  defmodule Float do
    @moduledoc """
    Type module for handling float values.
    """
    @type t :: float()

    @doc """
    Validates that a value is a float.

    ## Examples

        iex> Struct.Types.Float.from_term(3.14)
        {:ok, 3.14}

        iex> Struct.Types.Float.from_term(42)
        {:error, "Expected float, got 42"}
    """
    def from_term(value) when is_float(value), do: {:ok, value}
    def from_term(value), do: {:error, "Expected float, got #{inspect(value)}"}

    @doc """
    Validates that a value is a float, raising an error if validation fails.

    ## Examples

        iex> Struct.Types.Float.from_term!(3.14)
        3.14

        iex> Struct.Types.Float.from_term!(42)
        ** (ArgumentError) Expected float, got 42
    """
    def from_term!(value) do
      case from_term(value) do
        {:ok, value} -> value
        {:error, _} -> raise ArgumentError, "Expected float, got #{inspect(value)}"
      end
    end
  end
end
