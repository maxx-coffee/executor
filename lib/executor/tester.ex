defmodule Executor.Tester do
  def run() do
    data = %{email: "test@test3.com", gmaid: "USA_23", type: "lead_notification"}
    Yggdrasil.publish([name: "new_lead"], data)
  end
end
