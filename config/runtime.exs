import Config

config :ethereum_api,
  url:
    System.get_env("ETHEREUM_API_URL") || throw("Missing ETHEREUM_API_URL environment variable")
