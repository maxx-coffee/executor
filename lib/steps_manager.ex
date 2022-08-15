defmodule Executor.StepsManager do
  use GenServer, restart: :temporary

  # Client

  def start_link(message) do
    GenServer.start_link(__MODULE__, %{
      current: nil,
      previous: nil,
      trigger_message: message
    })
  end

  @impl true
  def init(ctx) do
    Process.flag(:trap_exit, true)
    {:ok, ctx}
  end

  def set(pid, attr, val) do
    GenServer.call(pid, {attr, val})
  end

  def kill(pid) do
    send(pid, :kill)
  end

  def get_state(pid), do: GenServer.call(pid, :state)

  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  def handle_call({attr, val}, _from, state) do
    state =
      state
      |> Map.put(attr, val)

    {:reply, state, state}
  end

  def handle_info(:kill, state) do
    {:stop, :normal, state}
  end
end
