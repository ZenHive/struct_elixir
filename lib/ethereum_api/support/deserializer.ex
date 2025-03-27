defmodule EthereumApi.Support.Deserializer do
  @moduledoc false

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

  @spec deserialize_list(any(), (any() -> Result.t(any(), any()))) :: Result.t(list(), any())
  def deserialize_list(list, deserializer) when is_list(list) do
    Enum.reduce_while(list, {:ok, []}, fn value, {:ok, acc} ->
      case deserializer.(value) do
        {:ok, value} -> {:cont, {:ok, [value | acc]}}
        {:error, _} -> {:halt, {:error, "Failed to parse elem #{inspect(value)}"}}
      end
    end)
    |> Result.map(&Enum.reverse/1)
  end

  def deserialize_list(value, _deserializer),
    do: {:error, "Expected a list, got #{inspect(value)}"}
end
