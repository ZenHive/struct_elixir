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
end
