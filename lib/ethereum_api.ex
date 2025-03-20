defmodule EthereumApi do
  require JsonRpc.ApiCreatorHelper

  JsonRpc.ApiCreatorHelper.create_no_arg_methods(__MODULE__.Worker, [
    {
      "Returns the current client version.",
      :web3_client_version,
      "web3_clientVersion",
      EthereumApi.Response.Web3ClientVersion
    },
    {
      "Returns the number of the most recent block.",
      :eth_block_number,
      "eth_blockNumber",
      EthereumApi.Response.EthBlockNumber
    }
  ])
end
