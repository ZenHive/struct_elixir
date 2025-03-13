import Config

config :etherium_api,
  url:
    System.get_env("ETHERIUM_API_URL") || throw("Missing ETHERIUM_API_URL environment variable")
