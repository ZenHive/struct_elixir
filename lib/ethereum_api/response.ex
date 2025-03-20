defmodule EthereumApi.Response do
  defmodule Web3ClientVersion do
    @type t :: String.t()

    def from_response(response) do
      with {:ok, ok} <- response do
        if String.valid?(ok) do
          {:ok, ok}
        else
          {:error, "Response should be a string, found #{inspect(ok)}"}
        end
      end
    end
  end

  defmodule EthBlockNumber do
    @type t :: EthereumApi.Types.Block.t()

    @spec from_response(JsonRpc.Response.t()) :: Result.t(t(), String.t())
    def from_response(response) do
      with {:ok, ok} <- response,
           do: EthereumApi.Types.Block.deserialize(ok)
    end
  end
end
