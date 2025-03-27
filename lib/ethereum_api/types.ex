defmodule EthereumApi.Types do
  require EthereumApi.Types.Helper

  defmodule Wei do
    @type t :: String.t()

    def deserialize(value), do: EthereumApi.Types.Quantity.deserialize(value)

    def deserialize!(value), do: EthereumApi.Types.Quantity.deserialize!(value)

    def is_wei?(value), do: EthereumApi.Types.Quantity.is_quantity?(value)
  end

  defmodule Tag do
    @type t :: String.t()

    def tags(), do: ["latest", "earliest", "pending", "safe", "finalized"]

    def deserialize(value) do
      if value in tags() do
        {:ok, value}
      else
        {:error, "Invalid tag: #{inspect(value)}"}
      end
    end

    def is_tag?(value) do
      case deserialize(value) do
        {:ok, _} -> true
        {:error, _} -> false
      end
    end

    @spec deserialize!(any()) :: t()
    def deserialize!(value) do
      case deserialize(value) do
        {:ok, value} -> value
        {:error, _} -> raise ArgumentError, "Expected a tag, found #{inspect(value)}"
      end
    end
  end

  defmodule Data do
    @type t :: String.t()

    def deserialize(value) when is_binary(value) do
      if is_data?(value) do
        {:ok, value}
      else
        deserialize_error(value)
      end
    end

    def deserialize(value), do: deserialize_error(value)

    defp deserialize_error(value), do: {:error, "Invalid data: #{inspect(value)}"}

    def is_data?(value) when is_binary(value) do
      String.match?(value, ~r/^0x[0-9a-fA-F]*$/)
    end

    def is_data?(_), do: false

    @spec deserialize!(any()) :: t()
    def deserialize!(value) do
      case deserialize(value) do
        {:ok, value} -> value
        {:error, _} -> raise ArgumentError, "Expected a Data, found #{inspect(value)}"
      end
    end
  end

  EthereumApi.Types.Helper.def_data_module(8)
  EthereumApi.Types.Helper.def_data_module(20)
  EthereumApi.Types.Helper.def_data_module(32)
  EthereumApi.Types.Helper.def_data_module(256)

  defmodule Syncing do
    @enforce_keys [:starting_block, :current_block, :highest_block, :additional_data]
    defstruct [:starting_block, :current_block, :highest_block, :additional_data]

    @type t :: %Syncing{
            starting_block: String.t(),
            current_block: String.t(),
            highest_block: String.t(),
            additional_data: map()
          }

    @spec deserialize(term()) :: Result.t(t(), String.t())
    def deserialize(false), do: {:ok, false}

    def deserialize(
          %{
            "startingBlock" => starting_block,
            "currentBlock" => current_block,
            "highestBlock" => highest_block
          } = map
        ) do
      with {:ok, starting_block} <- EthereumApi.Types.Quantity.deserialize(starting_block),
           {:ok, current_block} <- EthereumApi.Types.Quantity.deserialize(current_block),
           {:ok, highest_block} <- EthereumApi.Types.Quantity.deserialize(highest_block) do
        {:ok,
         %__MODULE__{
           starting_block: starting_block,
           current_block: current_block,
           highest_block: highest_block,
           additional_data: Map.drop(map, ["startingBlock", "currentBlock", "highestBlock"])
         }}
      end
    end

    def deserialize(value), do: {:error, "Invalid Syncing: #{inspect(value)}"}
  end

  defmodule Quantity do
    @type t :: String.t()

    def deserialize(value) when is_binary(value) do
      if is_quantity?(value) do
        {:ok, value}
      else
        deserialize_error(value)
      end
    end

    def deserialize(value), do: deserialize_error(value)

    defp deserialize_error(value), do: {:error, "Invalid quantity: #{inspect(value)}"}

    def is_quantity?(value) when is_binary(value) do
      String.match?(value, ~r/^0x[0-9a-fA-F]+$/)
    end

    def is_data?(_), do: false

    @spec deserialize!(any()) :: t()
    def deserialize!(value) do
      case deserialize(value) do
        {:ok, value} -> value
        {:error, _} -> raise ArgumentError, "Expected a quantity, found #{inspect(value)}"
      end
    end
  end

  defmodule Block do
    alias EthereumApi.Support.Deserializer

    @struct_fields [
      :number,
      :hash,
      :parent_hash,
      :nonce,
      :sha3_uncles,
      :logs_bloom,
      :transactions_root,
      :state_root,
      :receipts_root,
      :miner,
      :difficulty,
      :extra_data,
      :size,
      :gas_limit,
      :gas_used,
      :timestamp,
      :transactions,
      :uncles
    ]
    @enforce_keys @struct_fields
    defstruct @struct_fields

    @type t :: %__MODULE__{
            number: EthereumApi.Types.Quantity.t() | nil,
            hash: EthereumApi.Types.Data32.t() | nil,
            parent_hash: EthereumApi.Types.Data32.t(),
            nonce: EthereumApi.Types.Data8.t() | nil,
            sha3_uncles: EthereumApi.Types.Data32.t(),
            logs_bloom: EthereumApi.Types.Data256.t() | nil,
            transactions_root: EthereumApi.Types.Data32.t(),
            state_root: EthereumApi.Types.Data32.t(),
            receipts_root: EthereumApi.Types.Data32.t(),
            miner: EthereumApi.Types.Data20.t(),
            difficulty: EthereumApi.Types.Quantity.t(),
            extra_data: EthereumApi.Types.Data.t(),
            size: EthereumApi.Types.Quantity.t(),
            gas_limit: EthereumApi.Types.Quantity.t(),
            gas_used: EthereumApi.Types.Quantity.t(),
            timestamp: EthereumApi.Types.Quantity.t(),
            transactions: [EthereumApi.Types.Transaction.t() | EthereumApi.Types.Data32.t()],
            uncles: [EthereumApi.Types.Data32.t()]
          }

    @spec deserialize(term()) :: Result.t(t(), String.t())
    def deserialize(block) when is_map(block) do
      with {:ok, number} <-
             block["number"]
             |> Deserializer.deserialize_optional(&EthereumApi.Types.Quantity.deserialize/1)
             |> Result.map_err(&"Failed to parse field number of Block: #{&1}"),
           {:ok, hash} <-
             block["hash"]
             |> Deserializer.deserialize_optional(&EthereumApi.Types.Data32.deserialize/1)
             |> Result.map_err(&"Failed to parse field hash of Block: #{&1}"),
           {:ok, parent_hash} <-
             block["parentHash"]
             |> EthereumApi.Types.Data32.deserialize()
             |> Result.map_err(&"Failed to parse field parent_hash of Block: #{&1}"),
           {:ok, nonce} <-
             block["nonce"]
             |> Deserializer.deserialize_optional(&EthereumApi.Types.Data8.deserialize/1)
             |> Result.map_err(&"Failed to parse field nonce of Block: #{&1}"),
           {:ok, sha3_uncles} <-
             block["sha3Uncles"]
             |> EthereumApi.Types.Data32.deserialize()
             |> Result.map_err(&"Failed to parse field sha3_uncles of Block: #{&1}"),
           {:ok, logs_bloom} <-
             block["logsBloom"]
             |> Deserializer.deserialize_optional(&EthereumApi.Types.Data256.deserialize/1)
             |> Result.map_err(&"Failed to parse field logs_bloom of Block: #{&1}"),
           {:ok, transactions_root} <-
             block["transactionsRoot"]
             |> EthereumApi.Types.Data32.deserialize()
             |> Result.map_err(&"Failed to parse field transactions_root of Block: #{&1}"),
           {:ok, state_root} <-
             block["stateRoot"]
             |> EthereumApi.Types.Data32.deserialize()
             |> Result.map_err(&"Failed to parse field state_root of Block: #{&1}"),
           {:ok, receipts_root} <-
             block["receiptsRoot"]
             |> EthereumApi.Types.Data32.deserialize()
             |> Result.map_err(&"Failed to parse field receipts_root of Block: #{&1}"),
           {:ok, miner} <-
             block["miner"]
             |> EthereumApi.Types.Data20.deserialize()
             |> Result.map_err(&"Failed to parse field miner of Block: #{&1}"),
           {:ok, difficulty} <-
             block["difficulty"]
             |> EthereumApi.Types.Quantity.deserialize()
             |> Result.map_err(&"Failed to parse field difficulty of Block: #{&1}"),
           {:ok, extra_data} <-
             block["extraData"]
             |> EthereumApi.Types.Data.deserialize()
             |> Result.map_err(&"Failed to parse field extra_data of Block: #{&1}"),
           {:ok, size} <-
             block["size"]
             |> EthereumApi.Types.Quantity.deserialize()
             |> Result.map_err(&"Failed to parse field size of Block: #{&1}"),
           {:ok, gas_limit} <-
             block["gasLimit"]
             |> EthereumApi.Types.Quantity.deserialize()
             |> Result.map_err(&"Failed to parse field gas_limit of Block: #{&1}"),
           {:ok, gas_used} <-
             block["gasUsed"]
             |> EthereumApi.Types.Quantity.deserialize()
             |> Result.map_err(&"Failed to parse field gas_used of Block: #{&1}"),
           {:ok, timestamp} <-
             block["timestamp"]
             |> EthereumApi.Types.Quantity.deserialize()
             |> Result.map_err(&"Failed to parse field timestamp of Block: #{&1}"),
           {:ok, transactions} <-
             block["transactions"]
             |> deserialize_transactions()
             |> Result.map_err(&"Failed to parse field transactions of Block: #{&1}"),
           {:ok, uncles} <-
             block["uncles"]
             |> EthereumApi.Types.Data32.deserialize_list()
             |> Result.map_err(&"Failed to parse field uncles of Block: #{&1}") do
        {:ok,
         %__MODULE__{
           number: number,
           hash: hash,
           parent_hash: parent_hash,
           nonce: nonce,
           sha3_uncles: sha3_uncles,
           logs_bloom: logs_bloom,
           transactions_root: transactions_root,
           state_root: state_root,
           receipts_root: receipts_root,
           miner: miner,
           difficulty: difficulty,
           extra_data: extra_data,
           size: size,
           gas_limit: gas_limit,
           gas_used: gas_used,
           timestamp: timestamp,
           transactions: transactions,
           uncles: uncles
         }}
      else
        {:error, error} -> {:error, "Failed to deserialize Block: #{error}"}
      end
    end

    def deserialize(value), do: {:error, "Failed to deserialize Block: #{value}"}

    @spec deserialize_transactions(any()) ::
            Result.t(
              [EthereumApi.Types.Transaction.t() | EthereumApi.Types.Data32.t()],
              String.t()
            )
    def deserialize_transactions(transactions) when is_list(transactions) do
      Enum.reduce_while(transactions, {:ok, []}, fn elem, {:ok, acc} ->
        result =
          case elem do
            elem when is_map(elem) -> EthereumApi.Types.Transaction.deserialize(elem)
            elem -> EthereumApi.Types.Data32.deserialize(elem)
          end

        case result do
          {:ok, transaction} -> {:cont, {:ok, [transaction | acc]}}
          {:error, error} -> {:halt, {:error, "Invalid transaction in list: #{error}"}}
        end
      end)
      |> Result.map(&Enum.reverse/1)
    end

    def deserialize_transactions(transactions) do
      {:error, "Expected a list of transactions, got #{inspect(transactions)}"}
    end
  end

  defmodule Transaction do
    alias EthereumApi.Support.Deserializer

    @struct_fields [
      :block_hash,
      :block_number,
      :from,
      :gas,
      :gas_price,
      :hash,
      :input,
      :nonce,
      :to,
      :transaction_index,
      :value,
      :v,
      :r,
      :s
    ]
    @enforce_keys @struct_fields
    defstruct @struct_fields

    @type t :: %__MODULE__{
            block_hash: Option.t(EthereumApi.Types.Data32.t()),
            block_number: Option.t(EthereumApi.Types.Quantity.t()),
            from: EthereumApi.Types.Data20.t(),
            gas: EthereumApi.Types.Quantity.t(),
            gas_price: EthereumApi.Types.Wei.t(),
            hash: EthereumApi.Types.Data32.t(),
            input: EthereumApi.Types.Data.t(),
            nonce: EthereumApi.Types.Quantity.t(),
            to: Option.t(EthereumApi.Types.Data20.t()),
            transaction_index: Option.t(EthereumApi.Types.Quantity.t()),
            value: EthereumApi.Types.Wei.t(),
            v: EthereumApi.Types.Quantity.t(),
            r: EthereumApi.Types.Quantity.t(),
            s: EthereumApi.Types.Quantity.t()
          }

    @spec deserialize(term()) :: Result.t(t(), String.t())
    def deserialize(transaction) when is_map(transaction) do
      with {:ok, block_hash} <-
             transaction["blockHash"]
             |> Deserializer.deserialize_optional(&EthereumApi.Types.Data32.deserialize/1)
             |> Result.map_err(&"Failed to parse field block_hash of Transaction: #{&1}"),
           {:ok, block_number} <-
             transaction["blockNumber"]
             |> Deserializer.deserialize_optional(&EthereumApi.Types.Quantity.deserialize/1)
             |> Result.map_err(&"Failed to parse field block_number of Transaction: #{&1}"),
           {:ok, from} <-
             transaction["from"]
             |> EthereumApi.Types.Data20.deserialize()
             |> Result.map_err(&"Failed to parse field from of Transaction: #{&1}"),
           {:ok, gas} <-
             transaction["gas"]
             |> EthereumApi.Types.Quantity.deserialize()
             |> Result.map_err(&"Failed to parse field gas of Transaction: #{&1}"),
           {:ok, gas_price} <-
             transaction["gasPrice"]
             |> EthereumApi.Types.Wei.deserialize()
             |> Result.map_err(&"Failed to parse field gas_price of Transaction: #{&1}"),
           {:ok, hash} <-
             transaction["hash"]
             |> EthereumApi.Types.Data32.deserialize()
             |> Result.map_err(&"Failed to parse field hash of Transaction: #{&1}"),
           {:ok, input} <-
             transaction["input"]
             |> EthereumApi.Types.Data.deserialize()
             |> Result.map_err(&"Failed to parse field input of Transaction: #{&1}"),
           {:ok, nonce} <-
             transaction["nonce"]
             |> EthereumApi.Types.Quantity.deserialize()
             |> Result.map_err(&"Failed to parse field nonce of Transaction: #{&1}"),
           {:ok, to} <-
             transaction["to"]
             |> Deserializer.deserialize_optional(&EthereumApi.Types.Data20.deserialize/1)
             |> Result.map_err(&"Failed to parse field to of Transaction: #{&1}"),
           {:ok, transaction_index} <-
             transaction["transactionIndex"]
             |> Deserializer.deserialize_optional(&EthereumApi.Types.Quantity.deserialize/1)
             |> Result.map_err(&"Failed to parse field transaction_index of Transaction: #{&1}"),
           {:ok, value} <-
             transaction["value"]
             |> EthereumApi.Types.Wei.deserialize()
             |> Result.map_err(&"Failed to parse field value of Transaction: #{&1}"),
           {:ok, v} <-
             transaction["v"]
             |> EthereumApi.Types.Quantity.deserialize()
             |> Result.map_err(&"Failed to parse field v of Transaction: #{&1}"),
           {:ok, r} <-
             transaction["r"]
             |> EthereumApi.Types.Quantity.deserialize()
             |> Result.map_err(&"Failed to parse field r of Transaction: #{&1}"),
           {:ok, s} <-
             transaction["s"]
             |> EthereumApi.Types.Quantity.deserialize()
             |> Result.map_err(&"Failed to parse field s of Transaction: #{&1}") do
        {:ok,
         %__MODULE__{
           block_hash: block_hash,
           block_number: block_number,
           from: from,
           gas: gas,
           gas_price: gas_price,
           hash: hash,
           input: input,
           nonce: nonce,
           to: to,
           transaction_index: transaction_index,
           value: value,
           v: v,
           r: r,
           s: s
         }}
      end
    end

    def deserialize(value) do
      {:error, "Expected a map for transaction data, got #{inspect(value)}"}
    end
  end

  defmodule TransactionReceipt do
    alias EthereumApi.Support.Deserializer

    defmodule TransactionStatus do
      @type t :: :success | :failure | {:pre_byzantium, EthereumApi.Types.Data32.t()}

      def deserialize(status, nil) do
        case status do
          "0x1" ->
            {:ok, :success}

          "0x0" ->
            {:ok, :failure}

          _ ->
            {:error, "Invalid TransactionStatus: Invalid status: #{inspect(status)}"}
        end
      end

      def deserialize(nil, root) do
        with {:ok, root} <-
               EthereumApi.Types.Data32.deserialize(root)
               |> Result.map_err(&"Invalid TransactionStatus: Invalid root: #{&1}") do
          {:ok, {:pre_byzantium, root}}
        end
      end

      def deserialize(status, root) do
        {:error, "Invalid TransactionStatus: status(#{inspect(status)}), root(#{inspect(root)})"}
      end
    end

    defmodule Log do
      alias EthereumApi.Support.Deserializer

      @struct_fields [
        :removed,
        :log_index,
        :transaction_index,
        :transaction_hash,
        :block_hash,
        :block_number,
        :address,
        :data,
        :topics
      ]
      @enforce_keys @struct_fields
      defstruct @struct_fields

      @type t :: %__MODULE__{
              removed: boolean(),
              log_index: EthereumApi.Types.Quantity.t(),
              transaction_index: EthereumApi.Types.Quantity.t(),
              transaction_hash: EthereumApi.Types.Data32.t(),
              block_hash: EthereumApi.Types.Data32.t(),
              block_number: EthereumApi.Types.Quantity.t(),
              address: EthereumApi.Types.Data20.t(),
              data: EthereumApi.Types.Data.t(),
              topics: [EthereumApi.Types.Data32.t()]
            }

      @spec deserialize(term()) :: Result.t(t(), String.t())
      def deserialize(log) when is_map(log) do
        with {:ok, removed} <-
               log["removed"]
               |> Types.Bool.deserialize()
               |> Result.map_err(&"Failed to parse field removed of Log: #{&1}"),
             {:ok, log_index} <-
               log["logIndex"]
               |> EthereumApi.Types.Quantity.deserialize()
               |> Result.map_err(&"Failed to parse field log_index of Log: #{&1}"),
             {:ok, transaction_index} <-
               log["transactionIndex"]
               |> EthereumApi.Types.Quantity.deserialize()
               |> Result.map_err(&"Failed to parse field transaction_index of Log: #{&1}"),
             {:ok, transaction_hash} <-
               log["transactionHash"]
               |> EthereumApi.Types.Data32.deserialize()
               |> Result.map_err(&"Failed to parse field transaction_hash of Log: #{&1}"),
             {:ok, block_hash} <-
               log["blockHash"]
               |> EthereumApi.Types.Data32.deserialize()
               |> Result.map_err(&"Failed to parse field block_hash of Log: #{&1}"),
             {:ok, block_number} <-
               log["blockNumber"]
               |> EthereumApi.Types.Quantity.deserialize()
               |> Result.map_err(&"Failed to parse field block_number of Log: #{&1}"),
             {:ok, address} <-
               log["address"]
               |> EthereumApi.Types.Data20.deserialize()
               |> Result.map_err(&"Failed to parse field address of Log: #{&1}"),
             {:ok, data} <-
               log["data"]
               |> EthereumApi.Types.Data.deserialize()
               |> Result.map_err(&"Failed to parse field data of Log: #{&1}"),
             {:ok, topics} <-
               log["topics"]
               |> EthereumApi.Types.Data32.deserialize_list()
               |> Result.map_err(&"Failed to parse field topics of Log: #{&1}") do
          {:ok,
           %__MODULE__{
             removed: removed,
             log_index: log_index,
             transaction_index: transaction_index,
             transaction_hash: transaction_hash,
             block_hash: block_hash,
             block_number: block_number,
             address: address,
             data: data,
             topics: topics
           }}
        end
      end

      def deserialize(value) do
        {:error, "Expected a map for log data, got #{inspect(value)}"}
      end

      def deserialize_list(list) do
        EthereumApi.Support.Deserializer.deserialize_list(list, &deserialize/1)
        |> Result.map_err(&"Expected list of logs, got #{inspect(&1)}")
      end
    end

    @struct_fields [
      :transaction_hash,
      :transaction_index,
      :block_hash,
      :block_number,
      :from,
      :to,
      :cumulative_gas_used,
      :effective_gas_price,
      :gas_used,
      :contract_address,
      :logs,
      :logs_bloom,
      :type,
      :status
    ]
    @enforce_keys @struct_fields
    defstruct @struct_fields

    @type t :: %__MODULE__{
            transaction_hash: EthereumApi.Types.Data32.t(),
            transaction_index: EthereumApi.Types.Quantity.t(),
            block_hash: EthereumApi.Types.Data32.t(),
            block_number: EthereumApi.Types.Quantity.t(),
            from: EthereumApi.Types.Data20.t(),
            to: Option.t(EthereumApi.Types.Data20.t()),
            cumulative_gas_used: EthereumApi.Types.Quantity.t(),
            effective_gas_price: EthereumApi.Types.Quantity.t(),
            gas_used: EthereumApi.Types.Quantity.t(),
            contract_address: Option.t(EthereumApi.Types.Data20.t()),
            logs: [Log.t()],
            logs_bloom: EthereumApi.Types.Data256.t(),
            type: EthereumApi.Types.Quantity.t(),
            status: TransactionStatus.t()
          }

    @spec deserialize(term()) :: Result.t(t(), String.t())
    def deserialize(receipt) when is_map(receipt) do
      with {:ok, transaction_hash} <-
             receipt["transactionHash"]
             |> EthereumApi.Types.Data32.deserialize()
             |> Result.map_err(
               &"Failed to parse field transaction_hash of TransactionReceipt: #{&1}"
             ),
           {:ok, transaction_index} <-
             receipt["transactionIndex"]
             |> EthereumApi.Types.Quantity.deserialize()
             |> Result.map_err(
               &"Failed to parse field transaction_index of TransactionReceipt: #{&1}"
             ),
           {:ok, block_hash} <-
             receipt["blockHash"]
             |> EthereumApi.Types.Data32.deserialize()
             |> Result.map_err(&"Failed to parse field block_hash of TransactionReceipt: #{&1}"),
           {:ok, block_number} <-
             receipt["blockNumber"]
             |> EthereumApi.Types.Quantity.deserialize()
             |> Result.map_err(&"Failed to parse field block_number of TransactionReceipt: #{&1}"),
           {:ok, from} <-
             receipt["from"]
             |> EthereumApi.Types.Data20.deserialize()
             |> Result.map_err(&"Failed to parse field from of TransactionReceipt: #{&1}"),
           {:ok, to} <-
             receipt["to"]
             |> Deserializer.deserialize_optional(&EthereumApi.Types.Data20.deserialize/1)
             |> Result.map_err(&"Failed to parse field to of TransactionReceipt: #{&1}"),
           {:ok, cumulative_gas_used} <-
             receipt["cumulativeGasUsed"]
             |> EthereumApi.Types.Quantity.deserialize()
             |> Result.map_err(
               &"Failed to parse field cumulative_gas_used of TransactionReceipt: #{&1}"
             ),
           {:ok, effective_gas_price} <-
             receipt["effectiveGasPrice"]
             |> EthereumApi.Types.Quantity.deserialize()
             |> Result.map_err(
               &"Failed to parse field effective_gas_price of TransactionReceipt: #{&1}"
             ),
           {:ok, gas_used} <-
             receipt["gasUsed"]
             |> EthereumApi.Types.Quantity.deserialize()
             |> Result.map_err(&"Failed to parse field gas_used of TransactionReceipt: #{&1}"),
           {:ok, contract_address} <-
             receipt["contractAddress"]
             |> Deserializer.deserialize_optional(&EthereumApi.Types.Data20.deserialize/1)
             |> Result.map_err(
               &"Failed to parse field contract_address of TransactionReceipt: #{&1}"
             ),
           {:ok, logs} <-
             receipt["logs"]
             |> Log.deserialize_list()
             |> Result.map_err(&"Failed to parse field logs of TransactionReceipt: #{&1}"),
           {:ok, logs_bloom} <-
             receipt["logsBloom"]
             |> EthereumApi.Types.Data256.deserialize()
             |> Result.map_err(&"Failed to parse field logs_bloom of TransactionReceipt: #{&1}"),
           {:ok, type} <-
             receipt["type"]
             |> EthereumApi.Types.Quantity.deserialize()
             |> Result.map_err(&"Failed to parse field type of TransactionReceipt: #{&1}"),
           {:ok, status} <-
             TransactionStatus.deserialize(receipt["status"], receipt["root"])
             |> Result.map_err(&"Failed to parse field status of TransactionReceipt: #{&1}") do
        {:ok,
         %__MODULE__{
           transaction_hash: transaction_hash,
           transaction_index: transaction_index,
           block_hash: block_hash,
           block_number: block_number,
           from: from,
           to: to,
           cumulative_gas_used: cumulative_gas_used,
           effective_gas_price: effective_gas_price,
           gas_used: gas_used,
           contract_address: contract_address,
           logs: logs,
           logs_bloom: logs_bloom,
           type: type,
           status: status
         }}
      end
    end

    def deserialize(value) do
      {:error, "Expected a map for transaction receipt data, got #{inspect(value)}"}
    end
  end
end
