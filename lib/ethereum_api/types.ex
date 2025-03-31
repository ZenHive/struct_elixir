defmodule EthereumApi.Types do
  @moduledoc """
  Defines types and data structures used in Ethereum API interactions.

  This module provides type definitions and conversion functions for various Ethereum data types
  such as Wei, Tags, Data, Blocks, Transactions, Logs, and more. It includes validation and
  conversion functions to ensure data integrity when working with Ethereum API responses.
  """

  require EthereumApi.Types.Support

  defmodule Wei do
    @moduledoc """
    Represents Wei, the smallest unit of Ether.
    """
    @type t :: String.t()

    @doc """
    Converts a term to Wei format.

    Returns `{:ok, value}` if successful, `{:error, reason}` otherwise.

    ## Examples

        iex> EthereumApi.Types.Wei.from_term("0x1234")
        {:ok, "0x1234"}

        iex> EthereumApi.Types.Wei.from_term("1234")
        {:error, "Invalid quantity: \\"1234\\""}

        iex> EthereumApi.Types.Wei.from_term(1234)
        {:error, "Invalid quantity: 1234"}

        iex> EthereumApi.Types.Wei.from_term(:atom)
        {:error, "Invalid quantity: :atom"}

        iex> EthereumApi.Types.Wei.from_term([1, 2, 3])
        {:error, "Invalid quantity: [1, 2, 3]"}

        iex> EthereumApi.Types.Wei.from_term(%{key: "value"})
        {:error, "Invalid quantity: %{key: \\"value\\"}"}
    """
    @spec from_term(any()) :: Result.t(t(), String.t())
    def from_term(value), do: EthereumApi.Types.Quantity.from_term(value)

    @doc """
    Converts a term to Wei format.

    Raises `ArgumentError` if the conversion fails.

    ## Examples

        iex> EthereumApi.Types.Wei.from_term!("0x1234")
        "0x1234"

        iex> EthereumApi.Types.Wei.from_term!("1234")
        ** (ArgumentError) Expected a quantity, found "1234"

        iex> EthereumApi.Types.Wei.from_term!(1234)
        ** (ArgumentError) Expected a quantity, found 1234

        iex> EthereumApi.Types.Wei.from_term!(:atom)
        ** (ArgumentError) Expected a quantity, found :atom

        iex> EthereumApi.Types.Wei.from_term!([1, 2, 3])
        ** (ArgumentError) Expected a quantity, found [1, 2, 3]

        iex> EthereumApi.Types.Wei.from_term!(%{key: "value"})
        ** (ArgumentError) Expected a quantity, found %{key: "value"}
    """
    @spec from_term!(any()) :: t()
    def from_term!(value), do: EthereumApi.Types.Quantity.from_term!(value)

    @doc """
    Checks if a value is a valid Wei amount.

    ## Examples

        iex> EthereumApi.Types.Wei.is_wei?("0x1234")
        true

        iex> EthereumApi.Types.Wei.is_wei?("1234")
        false

        iex> EthereumApi.Types.Wei.is_wei?(1234)
        false
    """
    @spec is_wei?(any()) :: boolean()
    def is_wei?(value), do: EthereumApi.Types.Quantity.is_quantity?(value)
  end

  defmodule Tag do
    @moduledoc """
    Represents block tags used in Ethereum API calls.

    Valid tags include: "latest", "earliest", "pending", "safe", and "finalized".
    """
    @type t :: String.t()

    @doc """
    Returns a list of all valid block tags.

    ## Examples

        iex> EthereumApi.Types.Tag.tags()
        ["latest", "earliest", "pending", "safe", "finalized"]
    """
    @spec tags() :: [String.t()]
    def tags(), do: ["latest", "earliest", "pending", "safe", "finalized"]

    @doc """
    Converts a term to a valid block tag.

    Returns `{:ok, tag}` if successful, `{:error, reason}` otherwise.

    ## Examples

        iex> EthereumApi.Types.Tag.from_term("latest")
        {:ok, "latest"}

        iex> EthereumApi.Types.Tag.from_term("earliest")
        {:ok, "earliest"}

        iex> EthereumApi.Types.Tag.from_term("pending")
        {:ok, "pending"}

        iex> EthereumApi.Types.Tag.from_term("safe")
        {:ok, "safe"}

        iex> EthereumApi.Types.Tag.from_term("finalized")
        {:ok, "finalized"}

        iex> EthereumApi.Types.Tag.from_term("invalid")
        {:error, "Invalid tag: \\"invalid\\""}

        iex> EthereumApi.Types.Tag.from_term(123)
        {:error, "Invalid tag: 123"}

        iex> EthereumApi.Types.Tag.from_term(:atom)
        {:error, "Invalid tag: :atom"}

        iex> EthereumApi.Types.Tag.from_term([1, 2, 3])
        {:error, "Invalid tag: [1, 2, 3]"}

        iex> EthereumApi.Types.Tag.from_term(%{key: "value"})
        {:error, "Invalid tag: %{key: \\"value\\"}"}
    """
    @spec from_term(any()) :: Result.t(t(), String.t())
    def from_term(value) do
      if value in tags() do
        {:ok, value}
      else
        {:error, "Invalid tag: #{inspect(value)}"}
      end
    end

    @doc """
    Converts a term to a valid block tag.

    Raises `ArgumentError` if the conversion fails.

    ## Examples

        iex> EthereumApi.Types.Tag.from_term!("latest")
        "latest"

        iex> EthereumApi.Types.Tag.from_term!("earliest")
        "earliest"

        iex> EthereumApi.Types.Tag.from_term!("pending")
        "pending"

        iex> EthereumApi.Types.Tag.from_term!("safe")
        "safe"

        iex> EthereumApi.Types.Tag.from_term!("finalized")
        "finalized"

        iex> EthereumApi.Types.Tag.from_term!("invalid")
        ** (ArgumentError) Expected a tag, found "invalid"

        iex> EthereumApi.Types.Tag.from_term!(123)
        ** (ArgumentError) Expected a tag, found 123

        iex> EthereumApi.Types.Tag.from_term!(:atom)
        ** (ArgumentError) Expected a tag, found :atom

        iex> EthereumApi.Types.Tag.from_term!([1, 2, 3])
        ** (ArgumentError) Expected a tag, found [1, 2, 3]

        iex> EthereumApi.Types.Tag.from_term!(%{key: "value"})
        ** (ArgumentError) Expected a tag, found %{key: "value"}
    """
    @spec from_term!(any()) :: t()
    def from_term!(value) do
      case from_term(value) do
        {:ok, value} -> value
        {:error, _} -> raise ArgumentError, "Expected a tag, found #{inspect(value)}"
      end
    end

    @doc """
    Checks if a value is a valid block tag.

    ## Examples

        iex> EthereumApi.Types.Tag.is_tag?("latest")
        true

        iex> EthereumApi.Types.Tag.is_tag?("earliest")
        true

        iex> EthereumApi.Types.Tag.is_tag?("pending")
        true

        iex> EthereumApi.Types.Tag.is_tag?("safe")
        true

        iex> EthereumApi.Types.Tag.is_tag?("finalized")
        true

        iex> EthereumApi.Types.Tag.is_tag?("invalid")
        false

        iex> EthereumApi.Types.Tag.is_tag?(123)
        false
    """
    @spec is_tag?(any()) :: boolean()
    def is_tag?(value) do
      case from_term(value) do
        {:ok, _} -> true
        {:error, _} -> false
      end
    end
  end

  defmodule Data do
    @moduledoc """
    Represents arbitrary data in Ethereum. (Represented as a hexadecimal string prefixed with "0x")
    """
    @type t :: String.t()

    @doc """
    Converts a term to Data format.

    Returns `{:ok, value}` if successful, `{:error, reason}` otherwise.

    ## Examples

        iex> EthereumApi.Types.Data.from_term("0xfffabc")
        {:ok, "0xfffabc"}

        iex> EthereumApi.Types.Data.from_term("string")
        {:error, "Invalid data: \\"string\\""}

        iex> EthereumApi.Types.Data.from_term("0x1234")
        {:ok, "0x1234"}

        iex> EthereumApi.Types.Data.from_term("1234")
        {:error, "Invalid data: \\"1234\\""}

        iex> EthereumApi.Types.Data.from_term("0x")
        {:ok, "0x"}

        iex> EthereumApi.Types.Data.from_term("")
        {:error, "Invalid data: \\"\\""}

        iex> EthereumApi.Types.Data.from_term(123)
        {:error, "Invalid data: 123"}

        iex> EthereumApi.Types.Data.from_term(:atom)
        {:error, "Invalid data: :atom"}

        iex> EthereumApi.Types.Data.from_term([1, 2, 3])
        {:error, "Invalid data: [1, 2, 3]"}

        iex> EthereumApi.Types.Data.from_term(%{key: "value"})
        {:error, "Invalid data: %{key: \\"value\\"}"}
    """
    @spec from_term(any()) :: Result.t(t(), String.t())
    def from_term(value) when is_binary(value) do
      if is_data?(value) do
        {:ok, value}
      else
        from_term_error(value)
      end
    end

    def from_term(value), do: from_term_error(value)

    @spec from_term_error(any()) :: {:error, String.t()}
    defp from_term_error(value), do: {:error, "Invalid data: #{inspect(value)}"}

    @doc """
    Checks if a value is valid Data format.

    ## Examples

        iex> EthereumApi.Types.Data.is_data?("0xfffabc")
        true

        iex> EthereumApi.Types.Data.is_data?("string")
        false

        iex> EthereumApi.Types.Data.is_data?("0x1234")
        true

        iex> EthereumApi.Types.Data.is_data?("1234")
        false

        iex> EthereumApi.Types.Data.is_data?("0x")
        true

        iex> EthereumApi.Types.Data.is_data?("")
        false

        iex> EthereumApi.Types.Data.is_data?(123)
        false
    """
    @spec is_data?(any()) :: boolean()
    def is_data?(value) when is_binary(value) do
      String.match?(value, ~r/^0x[0-9a-fA-F]*$/)
    end

    def is_data?(_), do: false

    @doc """
    Converts a term to Data format.

    Raises `ArgumentError` if the conversion fails.

    ## Examples

        iex> EthereumApi.Types.Data.from_term!("0xfffabc")
        "0xfffabc"

        iex> EthereumApi.Types.Data.from_term!("string")
        ** (ArgumentError) Expected a Data, found "string"

        iex> EthereumApi.Types.Data.from_term!("0x1234")
        "0x1234"

        iex> EthereumApi.Types.Data.from_term!("1234")
        ** (ArgumentError) Expected a Data, found "1234"

        iex> EthereumApi.Types.Data.from_term!("0x")
        "0x"

        iex> EthereumApi.Types.Data.from_term!("")
        ** (ArgumentError) Expected a Data, found ""

        iex> EthereumApi.Types.Data.from_term!(123)
        ** (ArgumentError) Expected a Data, found 123

        iex> EthereumApi.Types.Data.from_term!(:atom)
        ** (ArgumentError) Expected a Data, found :atom

        iex> EthereumApi.Types.Data.from_term!([1, 2, 3])
        ** (ArgumentError) Expected a Data, found [1, 2, 3]

        iex> EthereumApi.Types.Data.from_term!(%{key: "value"})
        ** (ArgumentError) Expected a Data, found %{key: "value"}
    """
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
    @moduledoc """
    Represents the syncing status of an Ethereum node.

    Contains information about the current block synchronization progress.
    """
    @enforce_keys [:starting_block, :current_block, :highest_block, :additional_data]
    defstruct [:starting_block, :current_block, :highest_block, :additional_data]

    @type t :: %Syncing{
            starting_block: EthereumApi.Types.Quantity.t(),
            current_block: EthereumApi.Types.Quantity.t(),
            highest_block: EthereumApi.Types.Quantity.t(),
            additional_data: map()
          }

    @doc """
    Converts a term to Syncing struct.

    Returns `{:ok, value}` if successful, `{:error, reason}` otherwise.

    ## Examples

        iex> EthereumApi.Types.Syncing.from_term(%{
        ...>   "startingBlock" => "0x1234",
        ...>   "currentBlock" => "0x5678",
        ...>   "highestBlock" => "0x9abc"
        ...> })
        {:ok, %EthereumApi.Types.Syncing{
          starting_block: "0x1234",
          current_block: "0x5678",
          highest_block: "0x9abc",
          additional_data: %{}
        }}

        iex> EthereumApi.Types.Syncing.from_term(%{
        ...>   "startingBlock" => "invalid",
        ...>   "currentBlock" => "0x5678",
        ...>   "highestBlock" => "0x9abc"
        ...> })
        {:error, "Invalid Syncing: %{\\"currentBlock\\" => \\"0x5678\\", \\"highestBlock\\" => \\"0x9abc\\", \\"startingBlock\\" => \\"invalid\\"}"}

        iex> EthereumApi.Types.Syncing.from_term("not a map")
        {:error, "Invalid Syncing: \\"not a map\\""}

        iex> EthereumApi.Types.Syncing.from_term(123)
        {:error, "Invalid Syncing: 123"}

        iex> EthereumApi.Types.Syncing.from_term(:atom)
        {:error, "Invalid Syncing: :atom"}

        iex> EthereumApi.Types.Syncing.from_term([1, 2, 3])
        {:error, "Invalid Syncing: [1, 2, 3]"}
    """
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
      else
        _ -> {:error, "Invalid Syncing: #{inspect(map)}"}
      end
    end

    def from_term(value), do: {:error, "Invalid Syncing: #{inspect(value)}"}
  end

  defmodule Quantity do
    @moduledoc """
    Represents a numeric quantity in Ethereum.
    """
    @type t :: String.t()

    @doc """
    Converts a term to Quantity format.

    Returns `{:ok, value}` if successful, `{:error, reason}` otherwise.

    ## Examples

        iex> EthereumApi.Types.Quantity.from_term("0x1234")
        {:ok, "0x1234"}

        iex> EthereumApi.Types.Quantity.from_term("0x0")
        {:ok, "0x0"}

        iex> EthereumApi.Types.Quantity.from_term("0x")
        {:error, "Invalid quantity: \\"0x\\""}

        iex> EthereumApi.Types.Quantity.from_term("1234")
        {:error, "Invalid quantity: \\"1234\\""}

        iex> EthereumApi.Types.Quantity.from_term(1234)
        {:error, "Invalid quantity: 1234"}

        iex> EthereumApi.Types.Quantity.from_term(:atom)
        {:error, "Invalid quantity: :atom"}

        iex> EthereumApi.Types.Quantity.from_term([1, 2, 3])
        {:error, "Invalid quantity: [1, 2, 3]"}

        iex> EthereumApi.Types.Quantity.from_term(%{key: "value"})
        {:error, "Invalid quantity: %{key: \\"value\\"}"}
    """
    @spec from_term(any()) :: Result.t(t(), String.t())
    def from_term(value) when is_binary(value) do
      if is_quantity?(value) do
        {:ok, value}
      else
        from_term_error(value)
      end
    end

    def from_term(value), do: from_term_error(value)

    @spec from_term_error(any()) :: {:error, String.t()}
    defp from_term_error(value), do: {:error, "Invalid quantity: #{inspect(value)}"}

    @doc """
    Checks if a value is valid Quantity format.

    ## Examples

        iex> EthereumApi.Types.Quantity.is_quantity?("0x1234")
        true

        iex> EthereumApi.Types.Quantity.is_quantity?("0x0")
        true

        iex> EthereumApi.Types.Quantity.is_quantity?("0x")
        false

        iex> EthereumApi.Types.Quantity.is_quantity?("1234")
        false

        iex> EthereumApi.Types.Quantity.is_quantity?(1234)
        false
    """
    @spec is_quantity?(any()) :: boolean()
    def is_quantity?(value) when is_binary(value) do
      String.match?(value, ~r/^0x[0-9a-fA-F]+$/)
    end

    def is_quantity?(_), do: false

    @doc """
    Converts a term to Quantity format.

    Raises `ArgumentError` if the conversion fails.

    ## Examples

        iex> EthereumApi.Types.Quantity.from_term!("0x1234")
        "0x1234"

        iex> EthereumApi.Types.Quantity.from_term!("0x0")
        "0x0"

        iex> EthereumApi.Types.Quantity.from_term!("0x")
        ** (ArgumentError) Expected a quantity, found "0x"

        iex> EthereumApi.Types.Quantity.from_term!("1234")
        ** (ArgumentError) Expected a quantity, found "1234"

        iex> EthereumApi.Types.Quantity.from_term!(1234)
        ** (ArgumentError) Expected a quantity, found 1234

        iex> EthereumApi.Types.Quantity.from_term!(:atom)
        ** (ArgumentError) Expected a quantity, found :atom

        iex> EthereumApi.Types.Quantity.from_term!([1, 2, 3])
        ** (ArgumentError) Expected a quantity, found [1, 2, 3]

        iex> EthereumApi.Types.Quantity.from_term!(%{key: "value"})
        ** (ArgumentError) Expected a quantity, found %{key: "value"}
    """
    @spec from_term!(any()) :: t()
    def from_term!(value) do
      case from_term(value) do
        {:ok, value} -> value
        {:error, _} -> raise ArgumentError, "Expected a quantity, found #{inspect(value)}"
      end
    end
  end

  defmodule Block do
    @moduledoc """
    Represents an Ethereum block.
    """
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
    @moduledoc """
    Represents a transaction reference that can be either a hash or a full transaction.
    """
    @type t :: {:hash, EthereumApi.Types.Data32.t()} | {:full, EthereumApi.Types.Transaction.t()}

    @doc """
    Converts a term to TransactionEnum format.

    Returns `{:ok, value}` if successful, `{:error, reason}` otherwise.

    ## Examples

        iex> EthereumApi.Types.TransactionEnum.from_term(
        ...> "0x0000000000000000000000000000000000000000000000000000000000000000"
        ...> )
        {:ok, {:hash, "0x0000000000000000000000000000000000000000000000000000000000000000"}}

        iex> EthereumApi.Types.TransactionEnum.from_term(%{
        ...>   "from" => "0x0000000000000000000000000000000000000000",
        ...>   "gas" => "0x1234",
        ...>   "gasPrice" => "0x1234",
        ...>   "hash" => "0x0000000000000000000000000000000000000000000000000000000000000000",
        ...>   "input" => "0xffffffacb",
        ...>   "nonce" => "0x1234",
        ...>   "value" => "0x1234",
        ...>   "v" => "0x1234",
        ...>   "r" => "0x1234",
        ...>   "s" => "0x1234"
        ...> })
        {:ok, {:full, %EthereumApi.Types.Transaction{
          block_hash: nil,
          block_number: nil,
          from: "0x0000000000000000000000000000000000000000",
          gas: "0x1234",
          gas_price: "0x1234",
          hash: "0x0000000000000000000000000000000000000000000000000000000000000000",
          input: "0xffffffacb",
          nonce: "0x1234",
          to: nil,
          transaction_index: nil,
          value: "0x1234",
          v: "0x1234",
          r: "0x1234",
          s: "0x1234"
        }}}

        iex> EthereumApi.Types.TransactionEnum.from_term("invalid")
        {:error, "Invalid TransactionEnum: Invalid Data32: \\"invalid\\""}

        iex> EthereumApi.Types.TransactionEnum.from_term(%{})
        {
          :error,
          "Invalid TransactionEnum: Failed to parse field from of Elixir.EthereumApi.Types.Transaction: Invalid Data20: nil"
        }

        iex> EthereumApi.Types.TransactionEnum.from_term(123)
        {:error, "Invalid TransactionEnum: 123"}

        iex> EthereumApi.Types.TransactionEnum.from_term(:atom)
        {:error, "Invalid TransactionEnum: :atom"}

        iex> EthereumApi.Types.TransactionEnum.from_term([1, 2, 3])
        {:error, "Invalid TransactionEnum: [1, 2, 3]"}

        iex> EthereumApi.Types.TransactionEnum.from_term(%{key: "value"})
        {
          :error,
          "Invalid TransactionEnum: Failed to parse field from of Elixir.EthereumApi.Types.Transaction: Invalid Data20: nil"
        }
    """
    @spec from_term(any()) :: Result.t(t(), String.t())
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
    @moduledoc """
    Represents an Ethereum transaction.
    """
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

  defmodule Log do
    @moduledoc """
    Represents an Ethereum event log.
    """
    use Struct, {
      [Struct.FromTerm],
      [
        removed: Struct.Types.Bool,
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

  defmodule TransactionReceipt do
    @moduledoc """
    Represents the receipt of an executed transaction.
    """
    defmodule Status do
      @moduledoc """
      Represents the status of a transaction execution.
      """
      @type t :: :success | :failure | {:pre_byzantium, EthereumApi.Types.Data32.t()}

      @doc """
      Converts a term to TransactionStatus format.

      Returns `{:ok, value}` if successful, `{:error, reason}` otherwise.

      ## Examples

          iex> EthereumApi.Types.TransactionReceipt.Status.from_term("0x1")
          {:ok, :success}

          iex> EthereumApi.Types.TransactionReceipt.Status.from_term("0x0")
          {:ok, :failure}

          iex> EthereumApi.Types.TransactionReceipt.Status.from_term("0x0000000000000000000000000000000000000000000000000000000000000000")
          {:ok, {:pre_byzantium, "0x0000000000000000000000000000000000000000000000000000000000000000"}}

          iex> EthereumApi.Types.TransactionReceipt.Status.from_term("invalid")
          {:error, "Invalid TransactionStatus: \\"invalid\\""}

          iex> EthereumApi.Types.TransactionReceipt.Status.from_term(123)
          {:error, "Invalid TransactionStatus: 123"}

          iex> EthereumApi.Types.TransactionReceipt.Status.from_term(:atom)
          {:error, "Invalid TransactionStatus: :atom"}

          iex> EthereumApi.Types.TransactionReceipt.Status.from_term([1, 2, 3])
          {:error, "Invalid TransactionStatus: [1, 2, 3]"}

          iex> EthereumApi.Types.TransactionReceipt.Status.from_term(%{key: "value"})
          {:error, "Invalid TransactionStatus: %{key: \\"value\\"}"}
      """
      @spec from_term(String.t()) :: Result.t(t(), String.t())
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
          type: EthereumApi.Types.TransactionReceipt.Status,
          "Struct.FromTerm": [keys: ["status", "root"]]
        ]
      ]
    }
  end
end
