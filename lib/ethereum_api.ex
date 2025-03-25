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
        args: {data, EthereumApi.Types.Hexadecimal.t()},
        args_transformer!: &EthereumApi.Types.Hexadecimal.deserialize!/1,
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
        args_transformer!: fn address, block_number_or_tag ->
          [
            EthereumApi.Types.Data20.deserialize!(address),
            deserialize_quantity_or_tag!(block_number_or_tag)
          ]
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
        args_transformer!: fn address, position, block_number_or_tag ->
          [
            EthereumApi.Types.Data20.deserialize!(address),
            EthereumApi.Types.Quantity.deserialize!(position),
            deserialize_quantity_or_tag!(block_number_or_tag)
          ]
        end,
        response_type: {:type_alias, EthereumApi.Types.Data.t()},
        response_parser: &EthereumApi.Types.Data.deserialize/1
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
        args_transformer!: fn address, block_number_or_tag ->
          [
            EthereumApi.Types.Data20.deserialize!(address),
            deserialize_quantity_or_tag!(block_number_or_tag)
          ]
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
        args: {block_hash, EthereumApi.Types.Data32.t()},
        args_transformer!: &EthereumApi.Types.Data32.deserialize!/1,
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
        args: {block_number_or_tag, EthereumApi.Types.Quantity.t() | EthereumApi.Types.Tag.t()},
        args_transformer!: &deserialize_quantity_or_tag!/1,
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
        args: {block_hash, EthereumApi.Types.Data32.t()},
        args_transformer!: &EthereumApi.Types.Data32.deserialize!/1,
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
        args: {block_number_or_tag, EthereumApi.Types.Quantity.t() | EthereumApi.Types.Tag.t()},
        args_transformer!: &deserialize_quantity_or_tag!/1,
        response_type: {:type_alias, EthereumApi.Types.Quantity.t()},
        response_parser: &EthereumApi.Types.Quantity.deserialize/1
      },
      %{
        method: "eth_getCode",
        doc: """
          Returns code at a given address.

          # Parameters
          - address: The address to check for code
          - block_number_or_tag: Integer block number, or one of the following strings
            #{inspect(EthereumApi.Types.Tag.tags())}
        """,
        args: [
          {address, EthereumApi.Types.Data20.t()},
          {block_number_or_tag, EthereumApi.Types.Quantity.t() | EthereumApi.Types.Tag.t()}
        ],
        args_transformer!: fn address, block_number_or_tag ->
          [
            EthereumApi.Types.Data20.deserialize!(address),
            deserialize_quantity_or_tag!(block_number_or_tag)
          ]
        end,
        response_type: {:type_alias, EthereumApi.Types.Data.t()},
        response_parser: &EthereumApi.Types.Data.deserialize/1
      },
      %{
        method: "eth_sign",
        doc: """
          The sign method calculates an Ethereum specific signature with:
          sign(keccak256("\x19Ethereum Signed Message:\n" + len(message) + message))).

          By adding a prefix to the message makes the calculated signature recognizable as an
          Ethereum specific signature. This prevents misuse where a malicious dapp can sign
          arbitrary data (e.g. transaction) and use the signature to impersonate the victim.

          Note: the address to sign with must be unlocked.

          # Parameters
          - address: The address to sign with
          - data: The data to sign
        """,
        args: [
          {address, EthereumApi.Types.Data20.t()},
          {data, EthereumApi.Types.Data.t()}
        ],
        args_transformer!: fn address, data ->
          [
            EthereumApi.Types.Data20.deserialize!(address),
            EthereumApi.Types.Data.deserialize!(data)
          ]
        end,
        response_type: {:type_alias, EthereumApi.Types.Data.t()},
        response_parser: &EthereumApi.Types.Data.deserialize/1
      },
      %{
        method: "eth_signTransaction",
        doc: """
          Signs a transaction that can be submitted to the network at a later time using with
          eth_sendRawTransaction.

          # Parameters
          - from: The address the transaction is sent from.
          - data: The compiled code of a contract OR the hash of the invoked method signature and
            encoded parameters.
          - opts: A keyword list with the following options:
            - to: The address the transaction is directed to.
            - gas: Integer of the gas provided for the transaction execution. It will return unused
              gas.
            - gas_price: Integer of the gasPrice used for each paid gas, in Wei.
            - value: Integer of the value sent with this transaction, in Wei.
            - nonce: Integer of a nonce. This allows to overwrite your own pending transactions
              that use the same nonce.

          # Returns
          - Data - The RLP-encoded transaction object signed by the specified account.
        """,
        args: [
          {from, EthereumApi.Types.Data20.t()},
          {data, EthereumApi.Types.Data.t()},
          {opts,
           [
             {:to, EthereumApi.Types.Data20.t()},
             {:gas, EthereumApi.Types.Quantity.t()},
             {:gas_price, EthereumApi.Types.Wei.t()},
             {:value, EthereumApi.Types.Wei.t()},
             {:nonce, EthereumApi.Types.Quantity.t()}
           ]}
        ],
        args_transformer!: fn from, data, opts ->
          create_transaction_object(
            %{
              from: EthereumApi.Types.Data20.deserialize!(from),
              data: EthereumApi.Types.Data.deserialize!(data)
            },
            opts
          )
        end,
        response_type: {:type_alias, EthereumApi.Types.Data.t()},
        response_parser: &EthereumApi.Types.Data.deserialize/1
      }
    ]
  }

  defp create_transaction_object(transaction, opts) do
    Enum.reduce(opts, transaction, fn {opt, value}, acc ->
      value =
        cond do
          opt in [:gas, :nonce] ->
            EthereumApi.Types.Quantity.deserialize!(value)

          opt in [:gas_price, :value] ->
            EthereumApi.Types.Wei.deserialize!(value)

          opt in [:to, :from] ->
            EthereumApi.Types.Data20.deserialize!(value)

          opt == :data ->
            EthereumApi.Types.Data.deserialize!(value)

          true ->
            raise ArgumentError, "Invalid option: #{inspect(opt)}"
        end

      Map.get_and_update(acc, opt, fn
        nil -> value
        _ -> raise ArgumentError, "Invalid/Duplicate option: #{inspect(opt)}"
      end)
    end)
  end

  defp deserialize_quantity_or_tag!(value) do
    try do
      EthereumApi.Types.Quantity.deserialize!(value)
    rescue
      ArgumentError ->
        try do
          EthereumApi.Types.Tag.deserialize!(value)
        rescue
          ArgumentError ->
            raise ArgumentError, "Expected a quantity or tag, found #{inspect(value)}"
        end
    end
  end
end
