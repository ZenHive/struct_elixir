defmodule JsonRpc.ResponseTest do
  use ExUnit.Case, async: true
  alias JsonRpc.Response

  describe "parse_response/1" do
    test "parses a valid response with result" do
      raw_response = %{"jsonrpc" => "2.0", "id" => 42, "result" => "random_result"}

      assert Response.parse_response(raw_response) ==
               {:ok, {:ok, %Response.Ok{id: 42, result: "random_result"}}}
    end

    test "parses a valid response with error" do
      raw_response = %{
        "jsonrpc" => "2.0",
        "id" => 99,
        "error" => %{"code" => -32600, "message" => "Invalid Request"}
      }

      assert Response.parse_response(raw_response) ==
               {:ok,
                {:error,
                 %Response.Error{
                   id: 99,
                   code: %Response.Error.Code{code: -32600, description: :invalid_request},
                   message: "Invalid Request",
                   data: nil
                 }}}
    end

    test "returns error for non-compliant response" do
      raw_response = %{"jsonrpc" => "2.0", "id" => 77}

      assert Response.parse_response(raw_response) ==
               {:error, {:non_compliant_response, raw_response}}
    end
  end

  describe "parse_batch_responses/1" do
    test "parses a list of valid responses" do
      raw_responses = [
        %{"jsonrpc" => "2.0", "id" => 11, "result" => "resultA"},
        %{"jsonrpc" => "2.0", "id" => 22, "result" => "resultB"}
      ]

      expected_responses = %{
        11 => {:ok, %Response.Ok{id: 11, result: "resultA"}},
        22 => {:ok, %Response.Ok{id: 22, result: "resultB"}}
      }

      assert Response.parse_batch_responses(raw_responses) == {expected_responses, []}
    end

    test "parses a list with non-compliant responses" do
      raw_responses = [
        %{"jsonrpc" => "2.0", "id" => 33, "result" => "resultX"},
        %{"jsonrpc" => "2.0", "id" => 44}
      ]

      expected_responses = %{
        33 => {:ok, %Response.Ok{id: 33, result: "resultX"}}
      }

      assert Response.parse_batch_responses(raw_responses) ==
               {expected_responses,
                [{:non_compliant_response, %{"jsonrpc" => "2.0", "id" => 44}}]}
    end
  end
end
