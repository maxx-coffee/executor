defmodule Executor.Droids.AutoResponder do
  use Executor.Workflow
  alias Executor.Components.RetrieveNotification
  trigger("new_lead")

  steps do
    step "get_lead_notification" do
      inport(trigger_message() |> Map.put(:type, "autoresponder"))
      component(RetrieveNotification)
      error("done")
      next("retrieve_email_template")
      IO.inspect("klfjldafjsda")
    end
  end
end
