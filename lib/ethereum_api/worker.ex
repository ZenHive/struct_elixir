defmodule EthereumApi.Worker do
  @spec start_link(_ :: any()) :: Result.t(pid(), term())
  def start_link(url) do
    JsonRpc.Client.WebSocket.start_link(url, __MODULE__)
  end

  def child_spec(_) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [Application.fetch_env!(:ethereum_api, :url)]}
    }
  end
end
