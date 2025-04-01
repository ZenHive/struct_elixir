defmodule EthereumApi.Application do
  use Application

  def start(_type, _args) do
    Supervisor.start_link(
      [EthereumApi.Worker],
      strategy: :one_for_one,
      name: EthereumApi.Supervisor
    )
  end
end
