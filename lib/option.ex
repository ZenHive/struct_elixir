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
  def map(opt, f), do: f.(opt)

  @doc """
  Maps an Option.t(inner) to new_inner by applying a function to a contained value
  (if Some) or returns the default value (if nil).

  If default is expansive to compute, use `map_or_else/3` instead.

  ## Examples
      iex> Option.map_or("foo", "default", &String.length/1)
      3
      iex> Option.map_or(nil, "default", &String.length/1)
      "default"
  """
  @spec map_or(t(inner), new_inner, (inner -> new_inner)) :: new_inner
  def map_or(nil, default, _f), do: default
  def map_or(opt, _default, f), do: f.(opt)

  @doc """
  Maps an Option.t(inner) to new_inner by applying a function to a contained value
  (if Some) or computes the default value from the given function (if nil).

  ## Examples
      iex> Option.map_or_else("foo", fn -> "default" end, &String.length/1)
      3
      iex> Option.map_or_else(nil, fn -> "default" end, &String.length/1)
      "default"
  """
  @spec map_or_else(t(inner), (-> new_inner), (inner -> new_inner)) :: new_inner
  def map_or_else(nil, default_f, _f), do: default_f.()
  def map_or_else(opt, _default_f, f), do: f.(opt)

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
  def unwrap!(opt), do: opt

  @doc """
  Returns the contained value if Some, otherwise returns the default value.

  If default is expansive to compute, use `unwrap_or_else/2` instead.

  ## Examples
      iex> Option.unwrap_or("foo", "default")
      "foo"
      iex> Option.unwrap_or(nil, "default")
      "default"
  """
  @spec unwrap_or(t(inner), inner) :: inner
  def unwrap_or(opt, default), do: opt || default

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
