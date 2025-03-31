defmodule EthereumApi.TypesTest do
  use ExUnit.Case, async: true
  doctest EthereumApi.Types
  doctest EthereumApi.Types.Wei
  doctest EthereumApi.Types.Tag
  doctest EthereumApi.Types.Data
  doctest EthereumApi.Types.Data8
  doctest EthereumApi.Types.Data20
  doctest EthereumApi.Types.Data32
  doctest EthereumApi.Types.Data256
  doctest EthereumApi.Types.Syncing
  doctest EthereumApi.Types.Quantity
  doctest EthereumApi.Types.Block
  doctest EthereumApi.Types.TransactionEnum
  doctest EthereumApi.Types.Transaction
  doctest EthereumApi.Types.Log
  doctest EthereumApi.Types.TransactionReceipt
  doctest EthereumApi.Types.TransactionReceipt.Status
end
