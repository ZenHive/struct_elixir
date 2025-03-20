defmodule EthereumApi.Types do
  defmodule Block do
    @type t :: String.t()

    @spec deserialize(term()) :: {:ok, t()} | {:error, String.t()}
    def deserialize("0x" <> ""), do: {:error, "Invalid block number"}
    # TODO check that chars are hexa
    def deserialize("0x" <> _ = block), do: {:ok, block}
    def deserialize(_), do: {:error, "Invalid block number"}
  end
end
