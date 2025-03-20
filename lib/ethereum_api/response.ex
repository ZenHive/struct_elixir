defmodule EthereumApi.Response do
  defmodule Web3ClientVersion do
    @type t :: String.t()

    def from_response(response) do
      if String.valid?(response) do
        {:ok, response}
      else
        {:error, "Response should be a string, found #{inspect(response)}"}
      end
    end
  end

  defmodule EthBlockNumber do
    @type t :: EthereumApi.Types.Block.t()

    @spec from_response(JsonRpc.Response.t()) :: Result.t(t(), String.t())
    def from_response(response) do
      EthereumApi.Types.Block.deserialize(response)
    end
  end
end
