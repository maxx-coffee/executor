# steps: makeup of all workflow logic
# step: single piece of workflow logic
## inport: take the input for a step and allows the developer to mutate the data
## outport: allows users to export data for a specific step.  The outport also takes one argument which is the return of the component.
## next: the next step if the return of the component is {:ok, _}
## error: error step when the component returns {:error, _}
## trigger_message(): initial data that is passed to the first step of the workflow
## get_inport(): fetches the inport for a specific step
defmodule Executor.Droids.LeadNotification do
  use Executor.Workflow
  alias Executor.Components.RetrieveNotification
  alias Mocks.MockNotificationData

  trigger("new_lead")

  steps do
    step "get_lead_notification" do
      inport(trigger_message() |> Map.put(:type, "lead_notification"))
      component(RetrieveNotification)
      error("start_default_email")
      next("maybe_send_notification")
    end

    step "start_default_email" do
      component(fn _ ->
        data = trigger_message()
        emails = MockNotificationData.get_emails(data)

        if emails |> length() > 0 do
          emails
          |> Enum.map(fn email ->
            # send_email
            true
          end)

          {:ok, emails}
        else
          {:error, :no_emails}
        end
      end)

      error("log_unsent_emails")
      next("default_finished")
    end

    step "log_unsent_emails" do
      IO.inspect("Emails unsent")
    end

    step "default_finished" do
      component(fn _ ->
        IO.inspect("Default finished")
      end)
    end

    step "maybe_send_notification" do
      inport = get_inport()
      trigger_message = trigger_message()

      case inport do
        {:ok, %{status: "active"}} ->
          next("send_notification")

        _ ->
          next("done")
      end

      outport(fn _ ->
        {:ok, resp} = inport

        {:ok,
         resp
         |> Map.put(:email, trigger_message |> Map.get(:email))}
      end)
    end

    step "send_notification" do
      %{email: email} = trigger_message()
      IO.inspect("Sucessfully sent notification for #{email}")
    end

    step "done" do
      %{email: email} = trigger_message()
      IO.inspect("Inactive lead notification for #{email}")
    end
  end
end
