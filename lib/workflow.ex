defmodule Executor.Workflow do
  alias Executor.BlockSupervisor
  alias Executor.BlockManager
  alias Executor.StepsManager

  defmacro __using__(_) do
    Module.register_attribute(__CALLER__.module, :triggers,
      accumulate: true,
      persist: true
    )

    quote do
      import Executor.Workflow
      @behaviour unquote(__MODULE__)

      def run(input) do
        {:ok, step_manager} = BlockSupervisor.add_step_child(input)
        first_step = get_steps() |> List.last()
        resp = apply(__MODULE__, first_step, [step_manager])
        StepsManager.kill(step_manager)
        resp
      end

      def start_link(_) do
        GenServer.start_link(__MODULE__, %{steps: []})
      end

      def init(ctx) do
        {:ok, ctx}
      end

      def triggers() do
        @triggers
      end
    end
  end

  def children() do
    for({module, _} <- :code.all_loaded(), do: module)
    |> Enum.filter(&is_child?/1)
  end

  def is_child?(module) do
    module.module_info[:attributes]
    |> Keyword.get(:behaviour, [])
    |> Enum.member?(__MODULE__)
  end

  defmacro steps(do: block) do
    Module.register_attribute(__CALLER__.module, :steps,
      accumulate: true,
      persist: true
    )

    quote do
      unquote(block)
    end
  end

  defmacro trigger(trigger_sub) do
    Module.put_attribute(__CALLER__.module, :triggers, trigger_sub |> String.to_atom())

    quote do
      def unquote(trigger_sub |> String.to_existing_atom())(message) do
        __MODULE__.run(message)
      end
    end
  end

  defmacro get_steps() do
    quote do
      @steps
    end
  end

  defmacro step(name, do: block) do
    Module.put_attribute(__CALLER__.module, :steps, "step_#{name}" |> String.to_atom())

    quote do
      def unquote("step_#{name}" |> String.to_existing_atom())(step_manager) do
        {:ok, pid} = BlockSupervisor.add_child()
        %{trigger_message: trigger_message} = StepsManager.get_state(step_manager)
        var!(block_server) = pid
        var!(trigger_message) = trigger_message
        var!(step_manager) = step_manager
        _block_server = var!(block_server)
        _trigger_message = var!(trigger_message)
        _step_manager = var!(step_manager)
        unquote(block)
        BlockManager.finish_step(pid, {step_manager, __MODULE__})
      end
    end
  end

  defmacro next(val) do
    quote do
      block_server = var!(block_server)
      BlockManager.set(block_server, :next, unquote(val))
    end
  end

  defmacro error(val) do
    quote do
      block_server = var!(block_server)
      BlockManager.set(block_server, :error, unquote(val))
    end
  end

  defmacro component(component) do
    quote do
      block_server = var!(block_server)
      BlockManager.set(block_server, :component, unquote(component))
    end
  end

  defmacro inport(inport) do
    quote do
      block_server = var!(block_server)
      BlockManager.set(block_server, :inport, unquote(inport))
    end
  end

  defmacro get_inport() do
    quote do
      step_manager = var!(step_manager)
      %{previous: previous} = StepsManager.get_state(step_manager)
      previous[:outport]
    end
  end

  defmacro outport(outport) do
    quote do
      block_server = var!(block_server)
      BlockManager.set(block_server, :outport, unquote(outport))
    end
  end

  defmacro trigger_message do
    quote do
      var!(trigger_message)
    end
  end
end
