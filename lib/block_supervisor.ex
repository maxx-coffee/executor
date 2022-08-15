defmodule Executor.BlockSupervisor do
  use DynamicSupervisor
  alias Executor.BlockManager
  alias Executor.StepsManager

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def add_child() do
    DynamicSupervisor.start_child(__MODULE__, {BlockManager, []})
  end

  def add_step_child(message) do
    DynamicSupervisor.start_child(__MODULE__, {StepsManager, message})
  end
end
