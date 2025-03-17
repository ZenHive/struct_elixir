defmodule JsonRpc.Client.WebSocket do
  use WebSockex
  import JsonRpc.Request, only: [is_method: 1, is_params: 1]

  defmodule State do
    @enforce_keys [:next_id, :id_to_pid]
    defstruct [:next_id, :id_to_pid]

    @type t :: %__MODULE__{
            next_id: JsonRpc.RequestId.t(),
            id_to_pid: %{JsonRpc.RequestId.t() => {pid(), Time.t()}}
          }
  end

  @spec start_link(url :: String.t() | WebSockex.Conn.t(), WebSockex.options()) ::
          {:ok, pid()} | {:error, term()}
  def start_link(url, opts \\ []) do
    with {:ok, pid} <-
           WebSockex.start_link(url, __MODULE__, %State{next_id: 0, id_to_pid: %{}}, opts) do
      schedule_clean_unused_id_to_pids(pid)
      {:ok, pid}
    end
  end

  defp schedule_clean_unused_id_to_pids(pid) do
    Process.send_after(pid, :clean_unused_id_to_pids, :timer.seconds(3))
  end

  def handle_disconnect(connection_status_map, state) do
    Enum.each(state.id_to_pid, fn {_, {pid, _}} ->
      send(pid, {:json_rpc_error, :connection_closed})
    end)

    {:ok, %{state | id_to_pid: %{}}}
  end

  @spec call_with_params(WebSockex.client(), JsonRpc.Request.method(), JsonRpc.Request.params()) ::
          {:ok, JsonRpc.Response.t()} | {:error, term()}
  def call_with_params(client, method, params) when is_method(method) and is_params(params) do
    WebSockex.cast(client, {:call_with_params, {self(), method, params}})

    receive do
      {:json_rpc_frame, response} -> {:ok, response}
      {:json_rpc_error, reason} -> {:error, reason}
    end
  end

  @spec call_without_params(WebSockex.client(), JsonRpc.Request.method()) ::
          {:ok, JsonRpc.Response.t()} | {:error, term()}
  def call_without_params(client, method) when is_method(method) do
    WebSockex.cast(client, {:call_without_params, {self(), method}})

    receive do
      {:json_rpc_frame, response} -> {:ok, response}
      {:json_rpc_error, reason} -> {:error, reason}
    end
  end

  @spec notify_with_params(WebSockex.client(), JsonRpc.Request.method(), JsonRpc.Request.params()) ::
          :ok
  def notify_with_params(client, method, params) when is_method(method) and is_params(params) do
    WebSockex.cast(client, {:notify_with_params, {method, params}})
  end

  @spec notify_without_params(WebSockex.client(), JsonRpc.Request.method()) :: :ok
  def notify_without_params(client, method) when is_method(method) do
    WebSockex.cast(client, {:notify_without_params, method})
  end

  def handle_frame(:ping, state) do
    {:reply, :pong, state}
  end

  def handle_frame({:ping, value}, state) do
    {:reply, {:pong, value}, state}
  end

  def handle_frame({_, data}, state) do
    # TODO use a logger
    IO.puts("Received a frame: #{inspect(data)}")

    case Poison.decode(data) do
      {:error, reason} ->
        # TODO use a logger
        IO.puts("Failed to decode frame #{inspect(data)}, error: #{inspect(reason)}")
        {:ok, state}

      {:ok, data} ->
        parse_and_send_response(data, state)
    end
  end

  @spec parse_and_send_response(map(), State.t()) :: {:ok, State.t()}
  defp parse_and_send_response(data, state) do
    case JsonRpc.Response.parse_response(data) do
      {:error, reason} ->
        # TODO use a logger
        IO.puts("Failed to parse frame #{inspect(data)}, error: #{inspect(reason)}")
        {:ok, state}

      {:ok, response} ->
        send_response(response, state)
    end
  end

  @spec send_response(JsonRpc.Response.t(), State.t()) :: {:ok, State.t()}
  defp send_response(response, state) do
    case Map.fetch(state.id_to_pid, response.id) do
      :error ->
        # TODO use a logger
        IO.puts("invalid id in response #{response}")
        {:ok, state}

      {:ok, pid} ->
        send(pid, {:json_rpc_frame, response})
        {:ok, %State{state | id_to_pid: Map.delete(state.id_to_pid, response.id)}}
    end
  end

  def handle_cast(:clean_unused_id_to_pids, state) do
    new_id_to_pid =
      Map.filter(state.id_to_pid, fn {id, {pid, time}} ->
        if Time.diff(Time.utc_now(), time) > :timer.seconds(5) do
          # TODO use a logger
          IO.puts("Cleaning unused id_to_pid entry: #{id}")
          send(pid, {:json_rpc_error, :timeout})
          false
        else
          true
        end
      end)

    schedule_clean_unused_id_to_pids(self())

    {:ok, %State{state | id_to_pid: new_id_to_pid}}
  end

  def handle_cast({:call_with_params, {pid, method, params}}, state) do
    JsonRpc.Request.new_call_with_params(method, params, state.next_id)
    |> Poison.encode!()
    |> send_call_request_and_update_state(pid, state)
  end

  def handle_cast({:call_without_params, {pid, method}}, state) do
    JsonRpc.Request.new_call_without_params(method, state.next_id)
    |> Poison.encode!()
    |> send_call_request_and_update_state(pid, state)
  end

  def handle_cast({:notify_with_params, {method, params}}, state) do
    JsonRpc.Request.new_notify_with_params(method, params)
    |> Poison.encode!()
    |> send_notify_request(state)
  end

  def handle_cast({:notify_without_params, method}, state) do
    JsonRpc.Request.new_notify_without_params(method)
    |> Poison.encode!()
    |> send_notify_request(state)
  end

  defp send_call_request_and_update_state(request, pid, state) do
    # TODO use a logger
    IO.puts("Sending call request with payload: #{request}")

    new_state = %State{
      next_id: state.next_id + 1,
      id_to_pid: Map.put(state.id_to_pid, state.next_id, {pid, Time.utc_now()})
    }

    {:reply, {:text, request}, new_state}
  end

  defp send_notify_request(request, state) do
    # TODO use a logger
    IO.puts("Sending notify request with payload: #{request}")
    {:reply, {:text, request}, state}
  end
end
