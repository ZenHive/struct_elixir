defmodule EtheriumApi do
  defp url(), do: Application.fetch_env!(:etherium_api, :url)

  defp post!(%{} = json), do: HTTPoison.post(url(), Poison.encode!(json))

  @spec eth_block_number() :: EtheriumApi.Response.EthBlockNumber.t()
  def eth_block_number do
    post!(%{
      id: 1,
      jsonrpc: "2.0",
      method: "eth_blockNumber"
    })
    |> EtheriumApi.Response.EthBlockNumber.from_response()
  end
end
