defmodule JsonRpc.Request do
  alias JsonRpc.RequestId
  import RequestId, only: [is_id: 1]

  @type t :: map()
  @type method :: String.t()
  @type params :: map() | list()

  defguard is_request(request) when is_binary(request)
  defguard is_method(method) when is_binary(method)
  defguard is_params(params) when is_map(params) or is_list(params)

  @spec new_call_with_params(method :: method(), params :: params(), id :: RequestId.t()) :: t()
  def new_call_with_params(method, params, id)
      when is_method(method) and is_params(params) and is_id(id) do
    %{
      :jsonrpc => :"2.0",
      :method => method,
      :params => params,
      :id => id
    }
  end

  @spec new_call_without_params(method :: method(), id :: RequestId.t()) :: t()
  def new_call_without_params(method, id) when is_method(method) and is_id(id) do
    %{
      :jsonrpc => :"2.0",
      :method => method,
      :id => id
    }
  end

  @spec new_notify_with_params(method :: method(), params :: params()) :: t()
  def new_notify_with_params(method, params)
      when is_method(method) and is_params(params) do
    %{
      :jsonrpc => :"2.0",
      :method => method,
      :params => params
    }
  end

  @spec new_notify_without_params(method :: method()) :: t()
  def new_notify_without_params(method) when is_method(method) do
    %{
      :jsonrpc => :"2.0",
      :method => method
    }
  end
end
