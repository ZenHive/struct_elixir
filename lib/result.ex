defmodule Result do
  @type ok :: any()
  @type new_ok :: any()
  @type err :: any()
  @type new_err :: any()

  @type t(ok, err) :: {:ok, ok} | {:error, err}

  @doc """
  Returns true if the result is ok

  ## Examples
      iex> Result.is_ok?({:ok, 42})
      true
      iex> Result.is_ok?({:error, "error"})
      false
  """
  @spec is_ok?(t(ok, err)) :: boolean
  def is_ok?({:ok, _}), do: true
  def is_ok?(_), do: false

  @doc """
  Returns true if the result is ok and the value inside of it matches a predicate.

  ## Examples
      iex> Result.is_ok_and?({:ok, 42}, &(&1 == 42))
      true
      iex> Result.is_ok_and?({:ok, 40}, &(&1 == 42))
      false
      iex> Result.is_ok_and?({:error, 42}, &(&1 == 42))
      false
  """
  @spec is_ok_and?(t(ok, err), (ok -> boolean)) :: boolean
  def is_ok_and?({:ok, value}, f), do: f.(value)
  def is_ok_and?(_, _f), do: false

  @doc """
  Returns true if the result is an error

  ## Examples
      iex> Result.is_err?({:ok, 42})
      false
      iex> Result.is_err?({:error, "error"})
      true
  """
  @spec is_err?(t(ok, err)) :: boolean
  def is_err?({:error, _}), do: true
  def is_err?(_), do: false

  @doc """
  Returns true if the result is an error and the value inside of it matches a predicate.

  ## Examples
      iex> Result.is_err_and?({:error, "msg"}, &(&1 == "msg"))
      true
      iex> Result.is_err_and?({:error, "another msg"}, &(&1 == "msg"))
      false
      iex> Result.is_err_and?({:ok, "msg"}, &(&1 == "msg"))
      false
  """
  @spec is_err_and?(t(ok, err), (err -> boolean)) :: boolean
  def is_err_and?({:error, err}, f), do: f.(err)
  def is_err_and?(_, _f), do: false

  @doc """
  Maps a Result.t(ok, err) to Result.t(new_ok, err) by applying a function to a contained Ok value, leaving an Err value untouched.

  ## Examples
      iex> Result.map({:ok, 42}, &(&1 + 1))
      {:ok, 43}
      iex> Result.map({:error, "error"}, &(&1 + 1))
      {:error, "error"}
  """
  @spec map(t(ok, err), (ok -> new_ok)) :: t(new_ok, err)
  def map({:ok, value}, f), do: {:ok, f.(value)}
  def map(result, _f), do: result

  @doc """
  Returns the provided default (if Err), or applies a function to the contained value (if Ok).

  Arguments passed to map_or are eagerly evaluated; if you are passing the result of a function call, it is recommended to use map_or_else, which is lazily evaluated.

  ## Examples
      iex> Result.map_or({:ok, 42}, 0, &(&1 + 1))
      43
      iex> Result.map_or({:error, "error"}, 0, &(&1 + 1))
      0
  """
  @spec map_or(t(ok, err), new_ok, (ok -> new_ok)) :: new_ok
  def map_or({:ok, value}, _default, f), do: f.(value)
  def map_or(_result, default, _f), do: default

  @doc """
  Maps a Result.t(ok, err) to new_ok() by applying fallback function default to a contained Err value, or function f to a contained Ok value.

  ## Examples
      iex> Result.map_or_else({:ok, 42}, fn _err -> 42 end, &(&1 + 2))
      44
      iex> Result.map_or_else({:error, "error"}, fn _err -> 42 end, &(&1 + 2))
      42
  """
  @spec map_or_else(t(ok, err), (err -> new_ok), (ok -> new_ok)) :: new_ok
  def map_or_else({:ok, value}, _f_default, f), do: f.(value)
  def map_or_else({:error, err}, f_default, _f), do: f_default.(err)

  @doc """
  Maps a Result.t(ok, err) to Result.t(ok, new_err) by applying a function to a contained Err value, leaving an Ok value untouched.

  ## Examples
      iex> Result.map_err({:ok, 42}, &(&1 + 1))
      {:ok, 42}
      iex> Result.map_err({:error, 42}, &(&1 + 1))
      {:error, 43}
  """
  @spec map_err(t(ok, err), (err -> new_err)) :: t(ok, new_err)
  def map_err({:error, err}, f), do: {:error, f.(err)}
  def map_err(result, _f), do: result

  @doc """
  Calls a function with the contained value if Ok.

  Returns the original result.

  ## Examples
      iex> import ExUnit.CaptureIO
      iex>
      iex> Result.inspect({:ok, 42}, &(IO.inspect(&1)))
      {:ok, 42}
      iex> capture_io(fn -> Result.inspect({:ok, 42}, &(IO.inspect(&1))) end)
      "42\\n"
      iex>
      iex> Result.inspect({:error, 42}, &(IO.inspect(&1)))
      {:error, 42}
      iex> capture_io(fn -> Result.inspect({:error, 42}, &(IO.inspect(&1))) end)
      ""
  """
  @spec inspect(t(ok, err), (ok -> any)) :: t(ok, err)
  def inspect({:ok, value} = result, f) do
    f.(value)
    result
  end

  def inspect(result, _f), do: result

  @doc """
  Calls a function with the contained value if Err.

  Returns the original result.

  ## Examples
      iex> import ExUnit.CaptureIO
      iex>
      iex> Result.inspect_err({:ok, 42}, &(IO.inspect(&1)))
      {:ok, 42}
      iex> capture_io(fn -> Result.inspect_err({:ok, 42}, &(IO.inspect(&1))) end)
      ""
      iex>
      iex> Result.inspect_err({:error, 42}, &(IO.inspect(&1)))
      {:error, 42}
      iex> capture_io(fn -> Result.inspect_err({:error, 42}, &(IO.inspect(&1))) end)
      "42\\n"
  """
  @spec inspect_err(t(ok, err), (err -> any)) :: t(ok, err)
  def inspect_err({:error, err} = result, f) do
    f.(err)
    result
  end

  def inspect_err(result, _f), do: result

  @doc """
  Returns the contained Ok value or raise msg

  ## Examples
      iex> Result.expect!({:ok, 42}, "Foo")
      42
      iex> Result.expect!({:error, 42}, "Foo")
      ** (RuntimeError) Foo: 42
  """
  @spec expect!(t(ok, err), String.t()) :: ok
  def expect!({:ok, value}, _msg), do: value
  def expect!({:error, err}, msg), do: raise("#{msg}: #{inspect(err)}")

  @doc """
  Returns the contained Ok value or raises an error

  ## Examples
      iex> Result.unwrap!({:ok, 42})
      42
      iex> Result.unwrap!({:error, 42})
      ** (RuntimeError) Result.unwrap!() called with result {:error, 42}
  """
  @spec unwrap!(t(ok, err)) :: ok
  def unwrap!({:ok, value}), do: value
  def unwrap!(result), do: raise("Result.unwrap!() called with result #{inspect(result)}")

  @doc """
  Returns the contained Err value or raise msg

  ## Examples
      iex> Result.expect_err!({:error, 42}, "Foo")
      42
      iex> Result.expect_err!({:ok, 42}, "Foo")
      ** (RuntimeError) Foo: 42
  """
  @spec expect_err!(t(ok, err), String.t()) :: err
  def expect_err!({:error, err}, _msg), do: err
  def expect_err!({:ok, value}, msg), do: raise("#{msg}: #{inspect(value)}")

  @doc """
  Returns the contained Err value or raises an error

  ## Examples
      iex> Result.unwrap_err!({:error, 42})
      42
      iex> Result.unwrap_err!({:ok, 42})
      ** (RuntimeError) Result.unwrap_err!() called with result {:ok, 42}
  """
  @spec unwrap_err!(t(ok, err)) :: err
  def unwrap_err!({:error, err}), do: err
  def unwrap_err!(result), do: raise("Result.unwrap_err!() called with result #{inspect(result)}")

  @doc """
  Returns the result of applying a function to the contained value if Ok.
  Returns the original result if Err.

  ## Examples
      iex> Result.and_then({:ok, 42}, &({:ok, &1 + 1}))
      {:ok, 43}
      iex> Result.and_then({:ok, 42}, &({:error, &1 + 1}))
      {:error, 43}
      iex> Result.and_then({:error, 42}, &({:ok, &1 + 1}))
      {:error, 42}
  """
  @spec and_then(t(ok, err), (ok -> t(new_ok, err))) :: t(new_ok, err)
  def and_then({:ok, value}, f), do: f.(value)
  def and_then(result, _f), do: result

  @doc """
  Returns the contained Ok value or a default

  Arguments passed to unwrap_or are eagerly evaluated; if you are passing the result of a function call, it is recommended to use unwrap_or_else, which is lazily evaluated.

  ## Examples
      iex> Result.unwrap_or({:ok, 42}, 0)
      42
      iex> Result.unwrap_or({:error, 42}, 0)
      0
  """
  @spec unwrap_or(t(ok, err), ok) :: ok
  def unwrap_or({:ok, value}, _default), do: value
  def unwrap_or(_result, default), do: default

  @doc """
  Returns the contained Ok value or computes a default from a function

  ## Examples
      iex> Result.unwrap_or_else({:ok, 42}, fn _ -> 0 end)
      42
      iex> Result.unwrap_or_else({:error, 42}, fn _ -> 0 end)
      0
  """
  @spec unwrap_or_else(t(ok, err), (err -> ok)) :: ok
  def unwrap_or_else({:ok, value}, _f_default), do: value
  def unwrap_or_else({:error, err}, f_default), do: f_default.(err)

  @doc """
  Reduces a list while handling errors using Result types.

  This function is similar to Enum.reduce/3 but works with Result types. It will continue
  reducing until either:
  1. The list is exhausted (returns {:ok, final_acc})
  2. The reducer function returns an error (returns {:error, error})

  ## Parameters
    - list: The list to reduce over
    - acc: The initial accumulator value
    - f: A function that takes an element and accumulator, returning {:ok, new_acc} or {:error, error}

  ## Examples
      iex> Result.try_reduce([1, 2, 3], 0, fn x, acc -> {:ok, acc + x} end)
      {:ok, 6}

      iex> Result.try_reduce([1, 2, 3], 0, fn x, acc ->
      ...>   if x == 2, do: {:error, "found 2"}, else: {:ok, acc + x}
      ...> end)
      {:error, "found 2"}

      iex> Result.try_reduce([], 42, fn _x, acc -> {:ok, acc} end)
      {:ok, 42}
  """
  @spec try_reduce(list(any()), any(), (any(), any() -> Result.t(any(), any()))) ::
          Result.t(any(), any())
  def try_reduce(list, acc, f) do
    Enum.reduce_while(list, {:ok, acc}, fn elem, {:ok, acc} ->
      case f.(elem, acc) do
        {:ok, acc} -> {:cont, {:ok, acc}}
        {:error, error} -> {:halt, {:error, error}}
      end
    end)
  end
end
