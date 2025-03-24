defmodule EthereumApi.Types do
  defmodule Syncing do
    @enforce_keys [:starting_block, :current_block, :highest_block, :additional_data]
    defstruct [:starting_block, :current_block, :highest_block, :additional_data]

    @type t :: %Syncing{
            starting_block: String.t(),
            current_block: String.t(),
            highest_block: String.t(),
            additional_data: map()
          }

    @spec deserialize(term()) :: {:ok, t()} | {:error, String.t()}
    def deserialize(false), do: {:ok, false}

    def deserialize(
          %{
            "startingBlock" => starting_block,
            "currentBlock" => current_block,
            "highestBlock" => highest_block
          } = map
        ) do
      with {:ok, starting_block} <- EthereumApi.Types.Quantity.deserialize(starting_block),
           {:ok, current_block} <- EthereumApi.Types.Quantity.deserialize(current_block),
           {:ok, highest_block} <- EthereumApi.Types.Quantity.deserialize(highest_block) do
        {:ok,
         %__MODULE__{
           starting_block: starting_block,
           current_block: current_block,
           highest_block: highest_block,
           additional_data: Map.drop(map, ["startingBlock", "currentBlock", "highestBlock"])
         }}
      end
    end

    def deserialize(value), do: {:error, "Invalid Syncing: #{inspect(value)}"}
  end

  defmodule Quantity do
    @type t :: String.t()

    def deserialize(value), do: EthereumApi.Types.Hexadecimal.deserialize(value)
  end

  defmodule Hexadecimal do
    @type t :: String.t()

    def is_hexadecimal?(string) do
      String.match?(string, ~r/^0x[0-9a-fA-F]+$/)
    end

    def deserialize(value) when is_binary(value) do
      if is_hexadecimal?(value) do
        {:ok, value}
      else
        {:error, "Unexpected hexadecimal: #{inspect(value)}"}
      end
    end

    def deserialize(value), do: {:error, "Invalid hexadecimal: #{inspect(value)}"}
  end
end
