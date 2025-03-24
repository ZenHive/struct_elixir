defmodule EthereumApi.Types do
  defmodule Wei do
    @type t :: String.t()

    def deserialize(value), do: EthereumApi.Types.Quantity.deserialize(value)
  end

  defmodule Tag do
    @type t :: String.t()

    def tags(), do: ["latest", "earliest", "pending", "safe", "finalized"]

    def deserialize(value) do
      if value in tags() do
        {:ok, value}
      else
        {:error, "Invalid tag: #{inspect(value)}"}
      end
    end

    def is_tag?(value) do
      case deserialize(value) do
        {:ok, _} -> true
        {:error, _} -> false
      end
    end

    def is_tag!(value) do
      if is_tag?(value) do
        :ok
      else
        raise ArgumentError, "Expected a tag, found #{inspect(value)}"
      end
    end
  end

  defmodule Data do
    @type t :: String.t()

    def deserialize(value) do
      with {:ok, value} <- EthereumApi.Types.Hexadecimal.deserialize(value) do
        if String.length(value) == 42 do
          {:ok, value}
        else
          {:error, "Invalid data len: #{inspect(value)}"}
        end
      end
    end

    def is_data?(value) do
      case deserialize(value) do
        {:ok, _} -> true
        {:error, _} -> false
      end
    end

    def is_data!(value) do
      if is_data?(value) do
        :ok
      else
        raise ArgumentError, "Expected a data, found #{inspect(value)}"
      end
    end
  end

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

    def is_quantity?(value) do
      case deserialize(value) do
        {:ok, _} -> true
        {:error, _} -> false
      end
    end

    def is_quantity!(value) do
      if is_quantity?(value) do
        :ok
      else
        raise ArgumentError, "Expected a quantity, found #{inspect(value)}"
      end
    end
  end

  defmodule Hexadecimal do
    @type t :: String.t()

    def deserialize(value) when is_binary(value) do
      if is_hexadecimal?(value) do
        {:ok, value}
      else
        invalid_hexadecimal_error(value)
      end
    end

    def deserialize(value), do: invalid_hexadecimal_error(value)

    defp invalid_hexadecimal_error(value), do: {:error, "Invalid hexadecimal: #{inspect(value)}"}

    def is_hexadecimal?(string) do
      String.match?(string, ~r/^0x[0-9a-fA-F]+$/)
    end

    def is_hexadecimal!(value) do
      if is_hexadecimal?(value) do
        :ok
      else
        raise ArgumentError, "Expected a hexadecimal, found #{inspect(value)}"
      end
    end
  end
end
