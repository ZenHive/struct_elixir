defmodule JsonRpc.RequestId do
  @type t :: Option.t(integer() | String.t())

  defguard is_id(id) when is_integer(id) or is_binary(id) or is_nil(id)
end
