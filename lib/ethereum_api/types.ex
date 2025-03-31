defmodule EthereumApi.Types do
  @moduledoc """
  Defines types and data structures used in Ethereum API interactions.

  This module provides type definitions and conversion functions for various Ethereum data types
  such as Wei, Tags, Data, Blocks, Transactions, Logs, and more. It includes validation and
  conversion functions to ensure data integrity when working with Ethereum API responses.
  """

  require EthereumApi.Types.Support

  EthereumApi.Types.Support.def_data_module(8)
  EthereumApi.Types.Support.def_data_module(20)
  EthereumApi.Types.Support.def_data_module(32)
  EthereumApi.Types.Support.def_data_module(256)
end
