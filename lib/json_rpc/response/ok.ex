defmodule JsonRpc.Response.Ok do
  alias JsonRpc.RequestId
  import RequestId, only: [is_id: 1]

  @enforce_keys [:result, :id]
  defstruct [
    :result,
    :id
  ]

  @type t :: %__MODULE__{
          result: any(),
          id: RequestId.t()
        }

  def new(result, id) when is_id(id) do
    %__MODULE__{result: result, id: id}
  end
end
