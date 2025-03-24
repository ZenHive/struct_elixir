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
        doc: """
          Returns Keccak-256 (not the standardized SHA3-256) of the given data.

          # Parameters
          - data: The data to convert into a SHA3 hash
        """,
        args: [{data, EthereumApi.Types.Hexadecimal.t()}],
        args_checker!: &EthereumApi.Types.Hexadecimal.is_hexadecimal!/1,
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
        method: "eth_mining",
        doc: """
          Returns true if client is actively mining new blocks.
          This can only return true for proof-of-work networks and may not be available in some
          clients since The Merge.
        """,
        response_type: {:type_alias, Types.Bool.t()},
        response_parser: &Types.Bool.deserialize/1
      },
      %{
        method: "eth_hashrate",
        doc: """
          Returns the number of hashes per second that the node is mining with.
          This can only return true for proof-of-work networks and may not be available in some
          clients since The Merge.
        """,
        response_type: {:type_alias, EthereumApi.Types.Quantity.t()},
        response_parser: &EthereumApi.Types.Quantity.deserialize/1
      },
      %{
        method: "eth_gasPrice",
        doc: """
          Returns an estimate of the current price per gas in wei.
          For example, the Besu client examines the last 100 blocks and returns the median gas unit
          price by default.
        """,
        response_type: {:type_alias, EthereumApi.Types.Wei.t()},
        response_parser: &EthereumApi.Types.Wei.deserialize/1
      },
      %{
        method: "eth_accounts",
        doc: "Returns a list of addresses owned by client.",
        response_type: {:type_alias, [EthereumApi.Types.Data20.t()]},
        response_parser: fn
          list when is_list(list) ->
            result =
              Enum.reduce_while(list, {:ok, []}, fn elem, acc ->
                case EthereumApi.Types.Data20.deserialize(elem) do
                  {:ok, data} ->
                    {:cont, {:ok, [data | elem(acc, 1)]}}

                  {:error, reason} ->
                    {:halt, {:error, "Invalid data in list: #{inspect(reason)}"}}
                end
              end)

            with {:ok, result} <- result,
                 do: {:ok, Enum.reverse(result)}

          response ->
            {:error,
             "Invalid response, expect list(EthereumApi.Types.Data20.t()) found #{inspect(response)}"}
        end
      },
      %{
        method: "eth_blockNumber",
        doc: "Returns the number of the most recent block.",
        response_type: {:type_alias, EthereumApi.Types.Quantity.t()},
        response_parser: &EthereumApi.Types.Quantity.deserialize/1
      },
      %{
        method: "eth_getBalance",
        doc: """
          Returns the balance of the account of given address.

          # Parameters
          - address: The address to check for balance
          - block_number_or_tag: Integer block number, or one of the following strings
            #{inspect(EthereumApi.Types.Tag.tags())}
        """,
        args: [
          {address, EthereumApi.Types.Data20.t()},
          {block_number_or_tag, EthereumApi.Types.Quantity.t() | EthereumApi.Types.Tag.t()}
        ],
        args_checker!: fn address, block_number_or_tag ->
          EthereumApi.Types.Data20.is_data!(address)
          is_quantity_or_tag!(block_number_or_tag)
        end,
        response_type: {:type_alias, EthereumApi.Types.Wei.t()},
        response_parser: &EthereumApi.Types.Wei.deserialize/1
      },
      %{
        method: "eth_getStorageAt",
        doc: """
          Returns the value from a storage position at a given address.
          For more details, see:
          https://ethereum.org/en/developers/docs/apis/json-rpc/#eth_getstorageat

          # Parameters
          - address: The address of the storage
          - position: Integer of the position in the storage
          - block_number_or_tag: Integer block number, or one of the following strings
            #{inspect(EthereumApi.Types.Tag.tags())}
        """,
        args: [
          {address, EthereumApi.Types.Data20.t()},
          {position, EthereumApi.Types.Quantity.t()},
          {block_number_or_tag, EthereumApi.Types.Quantity.t() | EthereumApi.Types.Tag.t()}
        ],
        args_checker!: fn address, position, block_number_or_tag ->
          EthereumApi.Types.Data20.is_data!(address)
          EthereumApi.Types.Quantity.is_quantity!(position)
          is_quantity_or_tag!(block_number_or_tag)
        end,
        response_type: {:type_alias, EthereumApi.Types.Data32.t()},
        response_parser: &EthereumApi.Types.Data32.deserialize/1
      },
      %{
        method: "eth_getTransactionCount",
        doc: """
          Returns the number of transactions sent from an address.

          # Parameters
          - address: The address to check for transaction count
          - block_number_or_tag: Integer block number, or one of the following strings
            #{inspect(EthereumApi.Types.Tag.tags())}
        """,
        args: [
          {address, EthereumApi.Types.Data20.t()},
          {block_number_or_tag, EthereumApi.Types.Quantity.t() | EthereumApi.Types.Tag.t()}
        ],
        args_checker!: fn address, block_number_or_tag ->
          EthereumApi.Types.Data20.is_data!(address)
          is_quantity_or_tag!(block_number_or_tag)
        end,
        response_type: {:type_alias, EthereumApi.Types.Quantity.t()},
        response_parser: &EthereumApi.Types.Quantity.deserialize/1
      },
      %{
        method: "eth_getBlockTransactionCountByHash",
        doc: """
          Returns the number of transactions in a block from a block matching the given block hash.

          # Parameters
          - block_hash: The block hash
        """,
        args: [{block_hash, EthereumApi.Types.Data32.t()}],
        args_checker!: &EthereumApi.Types.Data32.is_data!/1,
        response_type: {:type_alias, EthereumApi.Types.Quantity.t()},
        response_parser: &EthereumApi.Types.Quantity.deserialize/1
      },
      %{
        method: "eth_getBlockTransactionCountByNumber",
        doc: """
          Returns the number of transactions in a block matching the given block number.

          # Parameters
          - block_number_or_tag: Integer block number, or one of the following strings
            #{inspect(EthereumApi.Types.Tag.tags())}
        """,
        args: [{block_number_or_tag, EthereumApi.Types.Quantity.t() | EthereumApi.Types.Tag.t()}],
        args_checker!: &is_quantity_or_tag!/1,
        response_type: {:type_alias, EthereumApi.Types.Quantity.t()},
        response_parser: &EthereumApi.Types.Quantity.deserialize/1
      },
      %{
        method: "eth_getUncleCountByBlockHash",
        doc: """
          Returns the number of uncles in a block from a block matching the given block hash.

          # Parameters
          - block_hash: The block hash
        """,
        args: [{block_hash, EthereumApi.Types.Data32.t()}],
        args_checker!: &EthereumApi.Types.Data32.is_data!/1,
        response_type: {:type_alias, EthereumApi.Types.Quantity.t()},
        response_parser: &EthereumApi.Types.Quantity.deserialize/1
      },
      %{
        method: "eth_getUncleCountByBlockNumber",
        doc: """
          Returns the number of uncles in a block from a block matching the given block number.

          # Parameters
          - block_number_or_tag: Integer block number, or one of the following strings
            #{inspect(EthereumApi.Types.Tag.tags())}
        """,
        args: [{block_number_or_tag, EthereumApi.Types.Quantity.t() | EthereumApi.Types.Tag.t()}],
        args_checker!: &is_quantity_or_tag!/1,
        response_type: {:type_alias, EthereumApi.Types.Quantity.t()},
        response_parser: &EthereumApi.Types.Quantity.deserialize/1
      }
    ]
  }

  defp is_quantity_or_tag!(value) do
    if not (EthereumApi.Types.Quantity.is_quantity?(value) or
              EthereumApi.Types.Tag.is_tag?(value)) do
      raise ArgumentError, "Expected a block number or a tag, found #{inspect(value)}"
    end
  end
end
