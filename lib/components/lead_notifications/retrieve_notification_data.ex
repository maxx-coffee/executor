defmodule Executor.Components.RetrieveNotification do
  alias Mocks.MockNotificationData

  def run(inport) do
    case MockNotificationData.get(inport) do
      nil -> {:error, :no_record}
      resp -> {:ok, resp}
    end
  end
end
