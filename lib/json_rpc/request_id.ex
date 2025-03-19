defmodule JsonRpc.RequestId do
  @type t :: integer() | String.t() | nil

  defguard is_id(id) when is_integer(id) or is_binary(id) or is_nil(id)
end
