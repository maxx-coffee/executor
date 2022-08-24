defmodule Executor.RegisterTriggers do
  use GenServer
  alias Executor.Workflow
  alias Executor.TriggerServer
  # Client

  def start_link(_) do
    prefix = "Executor"

    :code.all_available()
    |> Enum.filter(fn {name, _, loaded} ->
      !loaded && String.starts_with?(to_string(name), "Elixir." <> prefix)
    end)
    |> Enum.map(fn {name, _, _} -> name |> List.to_atom() end)
    |> :code.ensure_modules_loaded()

    GenServer.start_link(__MODULE__, [])
  end

  # Server (callbacks)

  @impl true
  def init(subscriptions) do
    Process.send_after(self(), :register_triggers, 1500)
    {:ok, []}
  end

  defp add_subscriptions([]) do
  end

  defp add_subscriptions([child | children]) do
    triggers = apply(child, :triggers, [])

    if triggers |> length() > 0 do
      TriggerServer.start_link({child, triggers})
    end

    add_subscriptions(children)
  end

  def handle_info(:register_triggers, state) do
    add_subscriptions(Workflow.children())
    {:noreply, state}
  end
end
