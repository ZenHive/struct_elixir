defmodule JsonRpc.RequestTest do
  use ExUnit.Case
  alias JsonRpc.Request

  describe "new_with_params/3" do
    test "creates a new request with params" do
      id = :rand.uniform(1000)
      method = "eth_method_" <> Integer.to_string(:rand.uniform(1000))

      params = %{
        ("param" <> Integer.to_string(:rand.uniform(10))) =>
          "value" <> Integer.to_string(:rand.uniform(10))
      }

      request = Request.new_with_params(method, params, id)

      assert request == %{
               jsonrpc: :"2.0",
               method: method,
               params: params,
               id: id
             }
    end
  end

  describe "new_without_params/2" do
    test "creates a new request without params" do
      id = :rand.uniform(1000)
      method = "eth_method_" <> Integer.to_string(:rand.uniform(1000))

      request = Request.new_without_params(method, id)

      assert request == %{
               jsonrpc: :"2.0",
               method: method,
               id: id
             }
    end
  end

  describe "new_notification_without_params/1" do
    test "creates a new notification without params" do
      method = "eth_method_" <> Integer.to_string(:rand.uniform(1000))

      notification = Request.new_notification_without_params(method)

      assert notification == %{
               jsonrpc: :"2.0",
               method: method
             }
    end
  end

  describe "new_notification_with_params/2" do
    test "creates a new notification with params" do
      method = "eth_method_" <> Integer.to_string(:rand.uniform(1000))

      params = %{
        ("param" <> Integer.to_string(:rand.uniform(10))) =>
          "value" <> Integer.to_string(:rand.uniform(10))
      }

      notification = Request.new_notification_with_params(method, params)

      assert notification == %{
               jsonrpc: :"2.0",
               method: method,
               params: params
             }
    end
  end
end
