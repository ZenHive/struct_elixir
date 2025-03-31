defmodule EthereumApi.Worker do
  @spec start_link(url :: String.t() | WebSockex.Conn.t()) :: Result.t(pid(), term())
  def start_link(url) do
    JsonRpc.Client.WebSocket.start_link(url, name: __MODULE__)
  end

  def child_spec(url) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [url]}
    }
  end
end
