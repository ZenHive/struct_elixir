defmodule Option do
  @type inner :: any()
  @type new_inner :: any()

  @type t(inner) :: inner | nil

  @doc """
  Maps an Option.t(inner) to Option.t(new_inner) by applying a function to a contained value
  (if Some) or returns nil (if nil).

  ## Examples
      iex> Option.map("foo", &String.length/1)
      3
      iex> Option.map(nil, &String.length/1)
      nil
  """
  @spec map(t(inner), (inner -> new_inner)) :: t(new_inner)
  def map(nil, _f), do: nil
  def map(value, f), do: f.(value)

  @doc """
  Returns the contained value if Some, otherwise raises an ArgumentError.

  ## Examples
      iex> Option.unwrap!("foo")
      "foo"
      iex> Option.unwrap!(nil)
      ** (ArgumentError) Option.unwrap! called on nil
  """
  @spec unwrap!(t(inner)) :: inner
  def unwrap!(nil), do: raise(ArgumentError, "Option.unwrap! called on nil")
  def unwrap!(value), do: value

  @doc """
  Returns the contained value if Some, otherwise returns the default value.

  ## Examples
      iex> Option.unwrap_or("foo", "default")
      "foo"
      iex> Option.unwrap_or(nil, "default")
      "default"
  """
  @spec unwrap_or(t(inner), inner) :: inner
  def unwrap_or(value, default), do: value || default

  @doc """
  Returns the contained value if Some, otherwise computes it from the given function.

  ## Examples
      iex> Option.unwrap_or_else("foo", fn -> "default" end)
      "foo"
      iex> Option.unwrap_or_else(nil, fn -> "default" end)
      "default"
  """
  @spec unwrap_or_else(t(inner), (-> inner)) :: inner
  def unwrap_or_else(value, f), do: value || f.()
end
