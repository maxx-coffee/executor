defmodule Executor do
  use Executor.Workflow
  alias Executor.Components.GeneratePdf

  steps do
    step "first" do
      inport_options = %{
        message: trigger_message()
      }

      inport(inport_options)

      component(GeneratePdf)
    end
  end
end
