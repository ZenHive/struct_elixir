defmodule JsonRpc.Response.Ok do
  @type t :: any()

  def new(result), do: result
end
