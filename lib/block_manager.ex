defmodule Executor.BlockManager do
  alias Executor.StepsManager
  use GenServer, restart: :temporary

  # Client

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{
      next: nil,
      error: nil,
      resp: nil,
      outport: nil,
      inport: nil,
      inport_resp: nil,
      outport_resp: {:ok, nil},
      component_resp: {:ok, nil}
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

  def get_state(pid) do
    GenServer.call(pid, :get_state)
  end

  def finish_step(pid, {step_manager, module}) do
    GenServer.call(pid, {:finish_step, step_manager, module}, :infinity)
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call(
        {:finish_step, step_manager, module},
        _from,
        state
      ) do
    StepsManager.set(step_manager, :current, self())

    %{
      step_manager: step_manager,
      module: module
    }
    |> Map.merge(state)
    |> handle_inport()
    |> handle_component()
    |> handle_outport()
    |> handle_resp()

    {:reply, :ok, state}
  end

  def handle_resp(
        %{outport_resp: {:error, _}, step_manager: step_manager, error: error, module: module} =
          state
      )
      when not is_nil(error) do
    update_steps(state)
    apply(module, "step_#{error}" |> String.to_atom(), [step_manager])

    Process.send_after(self(), :shutdown, 1)
    {:reply, state, state}
  end

  def run_next(next, resp) when is_function(next) do
    IO.inspect("step_#{next.(resp)}")

    "step_#{next.(resp)}"
    |> String.to_existing_atom()
  end

  def run_next(next, _resp) do
    IO.inspect("step_#{next}")

    "step_#{next}"
    |> String.to_existing_atom()
  end

  def handle_resp(
        %{outport_resp: {:ok, _}, next: next, module: module, step_manager: step_manager} = state
      )
      when not is_nil(next) do
    update_steps(state)
    next = run_next(next, state[:component_resp])
    apply(module, next, [step_manager])

    Process.send_after(self(), :shutdown, 1)
    {:reply, state, state}
  end

  def handle_resp(state) do
    update_steps(state)
    Process.send_after(self(), :shutdown, 1)
    {:reply, state, state}
  end

  defp update_steps(%{step_manager: step_manager, outport_resp: outport} = state) do
    StepsManager.set(step_manager, :current, nil)

    StepsManager.set(step_manager, :previous, %{
      outport: outport
    })
  end

  def handle_outport(%{component_resp: component_resp, outport: outport} = state) do
    resp =
      case outport do
        nil -> component_resp
        _ -> outport.(component_resp)
      end

    state
    |> Map.put(:outport_resp, resp)
  end

  def handle_inport(%{step_manager: step_manager, inport: inport} = state)
      when not is_nil(inport) and is_function(inport) do
    steps_state = StepsManager.get_state(step_manager)

    outport =
      case steps_state do
        %{previous: %{outport: outport}} ->
          outport

        _ ->
          %{}
      end

    state
    |> Map.put(:inport_resp, inport.(outport))
  end

  def handle_inport(%{inport: inport} = state)
      when not is_nil(inport) do
    state
    |> Map.put(:inport_resp, inport)
  end

  def handle_inport(state), do: state

  def handle_component(
        %{
          component: component,
          inport_resp: inport_resp
        } = state
      )
      when not is_nil(component) do
    resp =
      if is_function(component) do
        component.(inport_resp)
      else
        apply(component, :run, [inport_resp])
      end

    state
    |> Map.put(:component_resp, resp)
  end

  def handle_component(state), do: state

  @impl true
  def handle_call({attr, val}, _from, state) do
    state =
      state
      |> Map.put(attr, val)

    {:reply, state, state}
  end

  @impl true
  def handle_info(:shutdown, state) do
    {:stop, :normal, state}
  end

  def terminate(moo, _state) do
    :normal
  end
end
