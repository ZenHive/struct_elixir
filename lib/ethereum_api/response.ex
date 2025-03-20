defmodule EthereumApi.Response do
  defmodule EthBlockNumber do
    @type t :: EthereumApi.Types.Block.t()

    @spec from_response(JsonRpc.Response.t()) :: Result.t(t(), String.t())
    def from_response(response) do
      with {:ok, ok} <- response,
           do: EthereumApi.Types.Block.deserialize(ok)
    end
  end
end
