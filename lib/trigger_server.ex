defmodule Executor.TriggerServer do
  use GenServer
  alias Executor.Workflow
  # Client

  def start_link(state) do
    GenServer.start_link(__MODULE__, state)
  end

  # Server (callbacks)

  @impl true
  def init(state) do
    {:ok, state, {:continue, :register_triggers}}
  end

  def handle_continue(:register_triggers, {_module, triggers} = state) do
    IO.inspect(triggers)

    triggers
    |> Enum.each(fn trigger ->
      Yggdrasil.subscribe(name: trigger |> to_string())
    end)

    {:noreply, state}
  end

  def handle_info({:Y_EVENT, %{name: channel}, message}, {module, _} = state) do
    apply(module, channel |> String.to_existing_atom(), [message])

    {:noreply, state}
  end

  def handle_info({:Y_CONNECTED, _}, state), do: {:noreply, state}
end
