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
      with {:ok, number} =
             EthereumApi.Support.Deserializer.deserialize_optional(
               block["number"],
               &EthereumApi.Types.Quantity.deserialize/1
             )
             |> Result.map_err(fn err -> "Failed to parse field number of Block: #{err}" end),
           {:ok, hash} =
             EthereumApi.Support.Deserializer.deserialize_optional(
               block["hash"],
               &EthereumApi.Types.Data32.deserialize/1
             )
             |> Result.map_err(fn err -> "Failed to parse field hash of Block: #{err}" end),
           {:ok, parent_hash} <-
             EthereumApi.Types.Data32.deserialize(block["parentHash"])
             |> Result.map_err(fn err -> "Failed to parse field parent_hash of Block: #{err}" end),
           {:ok, nonce} =
             EthereumApi.Support.Deserializer.deserialize_optional(
               block["nonce"],
               &EthereumApi.Types.Data8.deserialize/1
             )
             |> Result.map_err(fn err -> "Failed to parse field nonce of Block: #{err}" end),
           {:ok, sha3_uncles} <-
             EthereumApi.Types.Data32.deserialize(block["sha3Uncles"])
             |> Result.map_err(fn err -> "Failed to parse field sha3_uncles of Block: #{err}" end),
           {:ok, logs_bloom} =
             EthereumApi.Support.Deserializer.deserialize_optional(
               block["logsBloom"],
               &EthereumApi.Types.Data256.deserialize/1
             )
             |> Result.map_err(fn err -> "Failed to parse field logs_bloom of Block: #{err}" end),
           {:ok, transactions_root} <-
             EthereumApi.Types.Data32.deserialize(block["transactionsRoot"])
             |> Result.map_err(fn err ->
               "Failed to parse field transactions_root of Block: #{err}"
             end),
           {:ok, state_root} <-
             EthereumApi.Types.Data32.deserialize(block["stateRoot"])
             |> Result.map_err(fn err -> "Failed to parse field state_root of Block: #{err}" end),
           {:ok, receipts_root} <-
             EthereumApi.Types.Data32.deserialize(block["receiptsRoot"])
             |> Result.map_err(fn err ->
               "Failed to parse field receipts_root of Block: #{err}"
             end),
           {:ok, miner} <-
             EthereumApi.Types.Data20.deserialize(block["miner"])
             |> Result.map_err(fn err -> "Failed to parse field miner of Block: #{err}" end),
           {:ok, difficulty} <-
             EthereumApi.Types.Quantity.deserialize(block["difficulty"])
             |> Result.map_err(fn err -> "Failed to parse field difficulty of Block: #{err}" end),
           {:ok, extra_data} <-
             EthereumApi.Types.Data.deserialize(block["extraData"])
             |> Result.map_err(fn err -> "Failed to parse field extra_data of Block: #{err}" end),
           {:ok, size} <-
             EthereumApi.Types.Quantity.deserialize(block["size"])
             |> Result.map_err(fn err -> "Failed to parse field size of Block: #{err}" end),
           {:ok, gas_limit} <-
             EthereumApi.Types.Quantity.deserialize(block["gasLimit"])
             |> Result.map_err(fn err -> "Failed to parse field gas_limit of Block: #{err}" end),
           {:ok, gas_used} <-
             EthereumApi.Types.Quantity.deserialize(block["gasUsed"])
             |> Result.map_err(fn err -> "Failed to parse field gas_used of Block: #{err}" end),
           {:ok, timestamp} <-
             EthereumApi.Types.Quantity.deserialize(block["timestamp"])
             |> Result.map_err(fn err -> "Failed to parse field timestamp of Block: #{err}" end),
           {:ok, transactions} <-
             deserialize_transactions(block["transactions"])
             |> Result.map_err(fn err ->
               "Failed to parse field transactions of Block: #{err}"
             end),
           {:ok, uncles} <-
             EthereumApi.Types.Data32.deserialize_list(block["uncles"])
             |> Result.map_err(fn err -> "Failed to parse field uncles of Block: #{err}" end) do
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
      with {:ok, block_hash} =
             EthereumApi.Support.Deserializer.deserialize_optional(
               transaction["blockHash"],
               &EthereumApi.Types.Data32.deserialize/1
             )
             |> Result.map_err(fn err ->
               "Failed to parse field block_hash of Transaction: #{err}"
             end),
           {:ok, block_number} =
             EthereumApi.Support.Deserializer.deserialize_optional(
               transaction["blockNumber"],
               &EthereumApi.Types.Quantity.deserialize/1
             )
             |> Result.map_err(fn err ->
               "Failed to parse field block_number of Transaction: #{err}"
             end),
           {:ok, from} <-
             EthereumApi.Types.Data20.deserialize(transaction["from"])
             |> Result.map_err(fn err -> "Failed to parse field from of Transaction: #{err}" end),
           {:ok, gas} <-
             EthereumApi.Types.Quantity.deserialize(transaction["gas"])
             |> Result.map_err(fn err -> "Failed to parse field gas of Transaction: #{err}" end),
           {:ok, gas_price} <-
             EthereumApi.Types.Wei.deserialize(transaction["gasPrice"])
             |> Result.map_err(fn err ->
               "Failed to parse field gas_price of Transaction: #{err}"
             end),
           {:ok, hash} <-
             EthereumApi.Types.Data32.deserialize(transaction["hash"])
             |> Result.map_err(fn err -> "Failed to parse field hash of Transaction: #{err}" end),
           {:ok, input} <-
             EthereumApi.Types.Data.deserialize(transaction["input"])
             |> Result.map_err(fn err -> "Failed to parse field input of Transaction: #{err}" end),
           {:ok, nonce} <-
             EthereumApi.Types.Quantity.deserialize(transaction["nonce"])
             |> Result.map_err(fn err -> "Failed to parse field nonce of Transaction: #{err}" end),
           {:ok, to} =
             EthereumApi.Support.Deserializer.deserialize_optional(
               transaction["to"],
               &EthereumApi.Types.Data20.deserialize/1
             )
             |> Result.map_err(fn err -> "Failed to parse field to of Transaction: #{err}" end),
           {:ok, transaction_index} =
             EthereumApi.Support.Deserializer.deserialize_optional(
               transaction["transactionIndex"],
               &EthereumApi.Types.Quantity.deserialize/1
             )
             |> Result.map_err(fn err ->
               "Failed to parse field transaction_index of Transaction: #{err}"
             end),
           {:ok, value} <-
             EthereumApi.Types.Wei.deserialize(transaction["value"])
             |> Result.map_err(fn err -> "Failed to parse field value of Transaction: #{err}" end),
           {:ok, v} <-
             EthereumApi.Types.Quantity.deserialize(transaction["v"])
             |> Result.map_err(fn err -> "Failed to parse field v of Transaction: #{err}" end),
           {:ok, r} <-
             EthereumApi.Types.Quantity.deserialize(transaction["r"])
             |> Result.map_err(fn err -> "Failed to parse field r of Transaction: #{err}" end),
           {:ok, s} <-
             EthereumApi.Types.Quantity.deserialize(transaction["s"])
             |> Result.map_err(fn err -> "Failed to parse field s of Transaction: #{err}" end) do
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
end
