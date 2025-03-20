defmodule EthereumApi.Application do
  use Application

  def start(_type, _args) do
    children = [
      {EthereumApi.Worker, Application.fetch_env!(:ethereum_api, :url)}
    ]

    opts = [strategy: :one_for_one, name: EthereumApi.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
