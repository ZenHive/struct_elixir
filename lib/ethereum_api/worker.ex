defmodule EthereumApi.Worker do
  alias JsonRpc.Client.WebSocket

  @spec start_link(url :: String.t() | WebSockex.Conn.t()) ::
          {:ok, pid()} | {:error, term()}
  def start_link(url) do
    WebSocket.start_link(url, name: __MODULE__)
  end

  def child_spec(url) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [url]}
    }
  end
end
