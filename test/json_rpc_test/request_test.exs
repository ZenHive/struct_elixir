defmodule JsonRpc.RequestTest do
  use ExUnit.Case, async: true
  alias JsonRpc.Request

  describe "new_call_with_params/3" do
    test "creates a new request with params" do
      id = :rand.uniform(1000)
      method = "eth_method_" <> Integer.to_string(:rand.uniform(1000))

      params = %{
        ("param" <> Integer.to_string(:rand.uniform(10))) =>
          "value" <> Integer.to_string(:rand.uniform(10))
      }

      request = Request.new_call_with_params(method, params, id)

      assert request == Poison.encode!(%{
               jsonrpc: :"2.0",
               method: method,
               params: params,
               id: id
             })
    end
  end

  describe "new_call_without_params/2" do
    test "creates a new request without params" do
      id = :rand.uniform(1000)
      method = "eth_method_" <> Integer.to_string(:rand.uniform(1000))

      request = Request.new_call_without_params(method, id)

      assert request == Poison.encode!(%{
               jsonrpc: :"2.0",
               method: method,
               id: id
             })
    end
  end

  describe "new_notify_with_params/2" do
    test "creates a new notification with params" do
      method = "eth_method_" <> Integer.to_string(:rand.uniform(1000))

      params = %{
        ("param" <> Integer.to_string(:rand.uniform(10))) =>
          "value" <> Integer.to_string(:rand.uniform(10))
      }

      notification = Request.new_notify_with_params(method, params)

      assert notification == Poison.encode!(%{
               jsonrpc: :"2.0",
               method: method,
               params: params
             })
    end
  end

  describe "new_notify_without_params/1" do
    test "creates a new notification without params" do
      method = "eth_method_" <> Integer.to_string(:rand.uniform(1000))

      notification = Request.new_notify_without_params(method)

      assert notification == Poison.encode!(%{
               jsonrpc: :"2.0",
               method: method
             })
    end
  end
end
