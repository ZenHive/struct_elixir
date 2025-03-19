defmodule JsonRpc.Response.Error do
  alias JsonRpc.RequestId
  import RequestId, only: [is_id: 1]

  @enforce_keys [:id, :code, :message, :data]
  defstruct [
    :id,
    :code,
    :message,
    :data
  ]

  @type t :: %__MODULE__{
          id: RequestId.t(),
          code: __MODULE__.Code.t(),
          message: String.t(),
          data: any()
        }

  @spec new(id :: RequestId.t(), code :: integer(), message :: String.t(), data :: any()) :: t()
  def new(id, code, message, data) when is_id(id) and is_integer(code) and is_binary(message) do
    %__MODULE__{id: id, code: __MODULE__.Code.new(code), message: message, data: data}
  end
end

defmodule JsonRpc.Response.Error.Code do
  @enforce_keys [:code, :description]
  defstruct [
    :code,
    :description
  ]

  @type t :: %__MODULE__{
          code: integer(),
          description: atom()
        }

  @spec new(new :: integer()) :: t()
  def new(code) when is_integer(code) do
    %__MODULE__{code: code, description: description_from_raw_code(code)}
  end

  @spec description_from_raw_code(code :: integer()) :: atom()
  defp description_from_raw_code(code) do
    case code do
      -32700 -> :parse_error
      -32600 -> :invalid_request
      -32601 -> :method_not_found
      -32602 -> :invalid_params
      -32603 -> :internal_error
      code when code in -32000..-32099//-1 -> :server_error
      _ -> :unknown_error
    end
  end
end
