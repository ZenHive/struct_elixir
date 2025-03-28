defmodule EthereumApi.Types do
  require EthereumApi.Types.Support

  defmodule Wei do
    @type t :: String.t()

    def from_term(value), do: EthereumApi.Types.Quantity.from_term(value)

    def from_term!(value), do: EthereumApi.Types.Quantity.from_term!(value)

    def is_wei?(value), do: EthereumApi.Types.Quantity.is_quantity?(value)
  end

  defmodule Tag do
    @type t :: String.t()

    def tags(), do: ["latest", "earliest", "pending", "safe", "finalized"]

    def from_term(value) do
      if value in tags() do
        {:ok, value}
      else
        {:error, "Invalid tag: #{inspect(value)}"}
      end
    end

    def is_tag?(value) do
      case from_term(value) do
        {:ok, _} -> true
        {:error, _} -> false
      end
    end

    @spec from_term!(any()) :: t()
    def from_term!(value) do
      case from_term(value) do
        {:ok, value} -> value
        {:error, _} -> raise ArgumentError, "Expected a tag, found #{inspect(value)}"
      end
    end
  end

  defmodule Data do
    @type t :: String.t()

    def from_term(value) when is_binary(value) do
      if is_data?(value) do
        {:ok, value}
      else
        from_term_error(value)
      end
    end

    def from_term(value), do: from_term_error(value)

    defp from_term_error(value), do: {:error, "Invalid data: #{inspect(value)}"}

    def is_data?(value) when is_binary(value) do
      String.match?(value, ~r/^0x[0-9a-fA-F]*$/)
    end

    def is_data?(_), do: false

    @spec from_term!(any()) :: t()
    def from_term!(value) do
      case from_term(value) do
        {:ok, value} -> value
        {:error, _} -> raise ArgumentError, "Expected a Data, found #{inspect(value)}"
      end
    end
  end

  EthereumApi.Types.Support.def_data_module(8)
  EthereumApi.Types.Support.def_data_module(20)
  EthereumApi.Types.Support.def_data_module(32)
  EthereumApi.Types.Support.def_data_module(256)

  defmodule Syncing do
    @enforce_keys [:starting_block, :current_block, :highest_block, :additional_data]
    defstruct [:starting_block, :current_block, :highest_block, :additional_data]

    @type t :: %Syncing{
            starting_block: EthereumApi.Types.Quantity.t(),
            current_block: EthereumApi.Types.Quantity.t(),
            highest_block: EthereumApi.Types.Quantity.t(),
            additional_data: map()
          }

    @spec from_term(term()) :: Result.t(t(), String.t())
    def from_term(false), do: {:ok, false}

    def from_term(
          %{
            "startingBlock" => starting_block,
            "currentBlock" => current_block,
            "highestBlock" => highest_block
          } = map
        ) do
      with {:ok, starting_block} <- EthereumApi.Types.Quantity.from_term(starting_block),
           {:ok, current_block} <- EthereumApi.Types.Quantity.from_term(current_block),
           {:ok, highest_block} <- EthereumApi.Types.Quantity.from_term(highest_block) do
        {:ok,
         %__MODULE__{
           starting_block: starting_block,
           current_block: current_block,
           highest_block: highest_block,
           additional_data: Map.drop(map, ["startingBlock", "currentBlock", "highestBlock"])
         }}
      end
    end

    def from_term(value), do: {:error, "Invalid Syncing: #{inspect(value)}"}
  end

  defmodule Quantity do
    @type t :: String.t()

    def from_term(value) when is_binary(value) do
      if is_quantity?(value) do
        {:ok, value}
      else
        from_term_error(value)
      end
    end

    def from_term(value), do: from_term_error(value)

    defp from_term_error(value), do: {:error, "Invalid quantity: #{inspect(value)}"}

    def is_quantity?(value) when is_binary(value) do
      String.match?(value, ~r/^0x[0-9a-fA-F]+$/)
    end

    def is_data?(_), do: false

    @spec from_term!(any()) :: t()
    def from_term!(value) do
      case from_term(value) do
        {:ok, value} -> value
        {:error, _} -> raise ArgumentError, "Expected a quantity, found #{inspect(value)}"
      end
    end
  end

  defmodule Block do
    use Struct, {
      [Struct.FromTerm],
      [
        number: [
          type: {:option, EthereumApi.Types.Quantity},
          "Struct.FromTerm": [keys: "number"]
        ],
        hash: [
          type: {:option, EthereumApi.Types.Data32},
          "Struct.FromTerm": [keys: "hash"]
        ],
        parent_hash: [
          type: EthereumApi.Types.Data32,
          "Struct.FromTerm": [keys: "parentHash"]
        ],
        nonce: [
          type: {:option, EthereumApi.Types.Data8},
          "Struct.FromTerm": [keys: "nonce"]
        ],
        sha3_uncles: [
          type: EthereumApi.Types.Data32,
          "Struct.FromTerm": [keys: "sha3Uncles"]
        ],
        logs_bloom: [
          type: {:option, EthereumApi.Types.Data256},
          "Struct.FromTerm": [keys: "logsBloom"]
        ],
        transactions_root: [
          type: EthereumApi.Types.Data32,
          "Struct.FromTerm": [keys: "transactionsRoot"]
        ],
        state_root: [
          type: EthereumApi.Types.Data32,
          "Struct.FromTerm": [keys: "stateRoot"]
        ],
        receipts_root: [
          type: EthereumApi.Types.Data32,
          "Struct.FromTerm": [keys: "receiptsRoot"]
        ],
        miner: [
          type: EthereumApi.Types.Data20,
          "Struct.FromTerm": [keys: "miner"]
        ],
        difficulty: [
          type: EthereumApi.Types.Quantity,
          "Struct.FromTerm": [keys: "difficulty"]
        ],
        extra_data: [
          type: EthereumApi.Types.Data,
          "Struct.FromTerm": [keys: "extraData"]
        ],
        size: [
          type: EthereumApi.Types.Quantity,
          "Struct.FromTerm": [keys: "size"]
        ],
        gas_limit: [
          type: EthereumApi.Types.Quantity,
          "Struct.FromTerm": [keys: "gasLimit"]
        ],
        gas_used: [
          type: EthereumApi.Types.Quantity,
          "Struct.FromTerm": [keys: "gasUsed"]
        ],
        timestamp: [
          type: EthereumApi.Types.Quantity,
          "Struct.FromTerm": [keys: "timestamp"]
        ],
        transactions: [
          type: {:list, EthereumApi.Types.TransactionEnum},
          "Struct.FromTerm": [keys: "transactions", default: []]
        ],
        uncles: [
          type: {:list, EthereumApi.Types.Data32},
          "Struct.FromTerm": [keys: "uncles"]
        ]
      ]
    }
  end

  defmodule TransactionEnum do
    @type t :: {:hash, EthereumApi.Types.Data32.t()} | {:full, EthereumApi.Types.Transaction.t()}

    def from_term(value) when is_map(value) do
      EthereumApi.Types.Transaction.from_term(value)
      |> Result.map(&{:full, &1})
      |> Result.map_err(&"Invalid TransactionEnum: #{&1}")
    end

    def from_term(value) when is_binary(value) do
      EthereumApi.Types.Data32.from_term(value)
      |> Result.map(&{:hash, &1})
      |> Result.map_err(&"Invalid TransactionEnum: #{&1}")
    end

    def from_term(value), do: {:error, "Invalid TransactionEnum: #{inspect(value)}"}
  end

  defmodule Transaction do
    use Struct, {
      [Struct.FromTerm],
      [
        block_hash: [
          type: {:option, EthereumApi.Types.Data32},
          "Struct.FromTerm": [keys: "blockHash"]
        ],
        block_number: [
          type: {:option, EthereumApi.Types.Quantity},
          "Struct.FromTerm": [keys: "blockNumber"]
        ],
        from: [type: EthereumApi.Types.Data20, "Struct.FromTerm": [keys: "from"]],
        gas: [type: EthereumApi.Types.Quantity, "Struct.FromTerm": [keys: "gas"]],
        gas_price: [type: EthereumApi.Types.Wei, "Struct.FromTerm": [keys: "gasPrice"]],
        hash: [type: EthereumApi.Types.Data32, "Struct.FromTerm": [keys: "hash"]],
        input: [type: EthereumApi.Types.Data, "Struct.FromTerm": [keys: "input"]],
        nonce: [type: EthereumApi.Types.Quantity, "Struct.FromTerm": [keys: "nonce"]],
        to: [type: {:option, EthereumApi.Types.Data20}, "Struct.FromTerm": [keys: "to"]],
        transaction_index: [
          type: {:option, EthereumApi.Types.Quantity},
          "Struct.FromTerm": [keys: "transactionIndex"]
        ],
        value: [type: EthereumApi.Types.Wei, "Struct.FromTerm": [keys: "value"]],
        v: [type: EthereumApi.Types.Quantity, "Struct.FromTerm": [keys: "v"]],
        r: [type: EthereumApi.Types.Quantity, "Struct.FromTerm": [keys: "r"]],
        s: [type: EthereumApi.Types.Quantity, "Struct.FromTerm": [keys: "s"]]
      ]
    }
  end

  defmodule TransactionReceipt do
    defmodule TransactionStatus do
      @type t :: :success | :failure | {:pre_byzantium, EthereumApi.Types.Data32.t()}

      def from_term(status) do
        case status do
          "0x1" ->
            {:ok, :success}

          "0x0" ->
            {:ok, :failure}

          root ->
            EthereumApi.Types.Data32.from_term(root)
            |> Result.map(&{:pre_byzantium, &1})
            |> Result.map_err(fn _err -> "Invalid TransactionStatus: #{inspect(status)}" end)
        end
      end
    end

    defmodule Log do
      use Struct, {
        [Struct.FromTerm],
        [
          removed: Types.Bool,
          log_index: [type: EthereumApi.Types.Quantity, "Struct.FromTerm": [keys: "logIndex"]],
          transaction_index: [
            type: EthereumApi.Types.Quantity,
            "Struct.FromTerm": [keys: "transactionIndex"]
          ],
          transaction_hash: [
            type: EthereumApi.Types.Data32,
            "Struct.FromTerm": [keys: "transactionHash"]
          ],
          block_hash: [type: EthereumApi.Types.Data32, "Struct.FromTerm": [keys: "blockHash"]],
          block_number: [
            type: EthereumApi.Types.Quantity,
            "Struct.FromTerm": [keys: "blockNumber"]
          ],
          address: EthereumApi.Types.Data20,
          data: EthereumApi.Types.Data,
          topics: {:list, EthereumApi.Types.Data32}
        ]
      }
    end

    use Struct, {
      [Struct.FromTerm],
      [
        transaction_hash: [
          type: EthereumApi.Types.Data32,
          "Struct.FromTerm": [keys: "transactionHash"]
        ],
        transaction_index: [
          type: EthereumApi.Types.Quantity,
          "Struct.FromTerm": [keys: "transactionIndex"]
        ],
        block_hash: [
          type: EthereumApi.Types.Data32,
          "Struct.FromTerm": [keys: "blockHash"]
        ],
        block_number: [
          type: EthereumApi.Types.Quantity,
          "Struct.FromTerm": [keys: "blockNumber"]
        ],
        from: EthereumApi.Types.Data20,
        to: {:option, EthereumApi.Types.Data20},
        cumulative_gas_used: [
          type: EthereumApi.Types.Quantity,
          "Struct.FromTerm": [keys: "cumulativeGasUsed"]
        ],
        effective_gas_price: [
          type: EthereumApi.Types.Quantity,
          "Struct.FromTerm": [keys: "effectiveGasPrice"]
        ],
        gas_used: [
          type: EthereumApi.Types.Quantity,
          "Struct.FromTerm": [keys: "gasUsed"]
        ],
        contract_address: [
          type: {:option, EthereumApi.Types.Data20},
          "Struct.FromTerm": [keys: "contractAddress"]
        ],
        logs: {:list, Log},
        logs_bloom: [
          type: EthereumApi.Types.Data256,
          "Struct.FromTerm": [keys: "logsBloom"]
        ],
        type: EthereumApi.Types.Quantity,
        status: [
          type: TransactionStatus,
          "Struct.FromTerm": [keys: ["status", "root"]]
        ]
      ]
    }
  end
end
