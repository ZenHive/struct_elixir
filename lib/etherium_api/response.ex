defmodule EtheriumApi.Response do
  defmacro __using__(fields) do
    quote do
      use JsonStruct, unquote(fields)

      def from_response(response) do
        with {:ok, response} <- response,
             {:error, reason} <- __MODULE__.deserialize(response.body),
             do: {:error, "Failed to parse response body #{reason}"}
      end
    end
  end

  def validate_jsonrpc("2.0"), do: true
  def validate_jsonrpc(_), do: false

  def validate_hex("0x" <> ""), do: false
  def validate_hex("0x" <> _), do: true
  def validate_hex(_), do: false
end

defmodule EtheriumApi.Response.EthBlockNumber do
  use EtheriumApi.Response,
    jsonrpc: {Types.Str, &EtheriumApi.Response.validate_jsonrpc/1},
    id: Types.Int,
    result: {Types.Str, &EtheriumApi.Response.validate_hex/1}
end
