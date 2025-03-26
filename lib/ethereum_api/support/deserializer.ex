defmodule EthereumApi.Support.Deserializer do
  @doc """
  Deserializes an optional value using the provided deserializer function.
  Returns {:ok, nil} if the value is nil, otherwise applies the deserializer.

  ## Examples
      iex> EthereumApi.Support.Deserializer.deserialize_optional(nil, fn v -> {:ok, String.length(v)} end)
      {:ok, nil}
      iex> EthereumApi.Support.Deserializer.deserialize_optional("hello", fn v -> {:ok, String.length(v)} end)
      {:ok, 5}
      iex> EthereumApi.Support.Deserializer.deserialize_optional(42, fn _v -> {:error, "invalid"} end)
      {:error, "invalid"}
  """
  @spec deserialize_optional(Option.t(any()), (any() -> Result.t(any(), any()))) ::
          Result.t(Option.t(any()), any())
  def deserialize_optional(nil, _deserializer), do: {:ok, nil}
  def deserialize_optional(value, deserializer), do: deserializer.(value)
end
