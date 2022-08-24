defmodule Mocks.MockNotificationData do
  @spec get(any) ::
          nil
          | %{
              :status => <<_::48, _::_*16>>,
              :type => <<_::104, _::_*32>>,
              optional(:gmaid) => <<_::48>>,
              optional(:id) => 1
            }
  def get(%{gmaid: "USA_22", type: "autoresponder"}) do
    ## mimics a DB call to check if a user has turned the autoresponder on

    %{
      id: 1,
      gmaid: "USA_22",
      status: "active",
      type: "autoresponder"
    }
  end

  def get(%{gmaid: "USA_22", type: "lead_notification", email: email}) do
    ## mimics a DB call to check if the user has lead notifications on
    %{
      id: 1,
      gmaid: "USA_22",
      status: "inactive",
      type: "lead_notification"
    }
  end

  # def get(%{type: "lead_notification"}) do
  #   %{
  #     status: "active",
  #     type: "lead_notification"
  #   }
  # end

  def get(_) do
    nil
  end

  def get_emails(%{gmaid: "USA_20"}) do
    ["test@test3.com", "test@test4.com"]
  end

  def get_emails(_), do: []
end
