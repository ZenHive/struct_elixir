defmodule EthereumApi do
  use JsonRpc.ApiCreator, {
    __MODULE__.Worker,
    [
      %{
        method: "web3_clientVersion",
        doc: "Returns the current client version.",
        response_type: {:type_alias, String.t()},
        response_parser: &Types.Str.deserialize/1
      },
      %{
        method: "web3_sha3",
        doc: "Returns Keccak-256 (not the standardized SHA3-256) of the given data.",
        args: [{data, String.t()}],
        args_checker!: fn data ->
          if !EthereumApi.Types.Hexadecimal.is_hexadecimal?(data) do
            throw("Expected a hexadecimal string, found #{inspect(data)}")
          end
        end,
        response_type: {:type_alias, String.t()},
        response_parser: &EthereumApi.Types.Hexadecimal.deserialize/1
      },
      %{
        method: "net_version",
        doc: "Returns the current network id.",
        response_type: {:type_alias, String.t()},
        response_parser: &Types.Str.deserialize/1
      },
      %{
        method: "net_listening",
        doc: "Returns true if client is actively listening for network connections.",
        response_type: {:type_alias, Types.Bool.t()},
        response_parser: &Types.Bool.deserialize/1
      },
      %{
        method: "net_peerCount",
        doc: "Returns number of peers currently connected to the client.",
        response_type: {:type_alias, EthereumApi.Types.Quantity.t()},
        response_parser: &EthereumApi.Types.Quantity.deserialize/1
      },
      %{
        method: "eth_protocolVersion",
        doc: """
          Returns the current Ethereum protocol version.

          Note that this method is not available in Geth
          (see https://github.com/ethereum/go-ethereum/pull/22064#issuecomment-788682924).
        """,
        response_type: {:type_alias, String.t()},
        response_parser: &Types.Str.deserialize/1
      },
      %{
        method: "eth_syncing",
        doc: "Returns an object with data about the sync status or false.",
        response_type: {:type_alias, false | EthereumApi.Types.Syncing.t()},
        response_parser: fn
          false ->
            {:ok, false}

          response ->
            EthereumApi.Types.Syncing.deserialize(response)
        end
      },
      %{
        method: "eth_chainId",
        doc: "Returns the chain ID used for signing replay-protected transactions.",
        response_type: {:type_alias, EthereumApi.Types.Hexadecimal.t()},
        response_parser: &EthereumApi.Types.Hexadecimal.deserialize/1
      },
      %{
        method: "eth_blockNumber",
        doc: "Returns the number of the most recent block.",
        response_type: {:type_alias, EthereumApi.Types.Quantity.t()},
        response_parser: &EthereumApi.Types.Quantity.deserialize/1
      }
    ]
  }
end
