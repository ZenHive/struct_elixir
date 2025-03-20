defmodule EthereumApi do
  alias JsonRpc.Client.WebSocket

  @client __MODULE__.Worker

  @spec eth_block_number() :: Result.t(EthereumApi.Response.EthBlockNumber.t(), any())
  def eth_block_number() do
    with {:ok, response} <- WebSocket.call_without_params(@client, "eth_blockNumber"),
         do: EthereumApi.Response.EthBlockNumber.from_response(response)
  end
end
