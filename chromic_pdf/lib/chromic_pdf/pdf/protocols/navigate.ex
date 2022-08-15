defmodule ChromicPDF.Navigate do
  @moduledoc false

  import ChromicPDF.ProtocolMacros

  steps do
    if_option :set_header do
      # call(:set_cookie, "Network.setCookie", &Map.fetch!(&1, :set_cookie), %{})
      # await_response(:cookie_set, [])

      call(
        :set_user_agent,
        "Network.setUserAgentOverride",
        fn options ->
          %{"userAgent" => "wkhtmltopdf"}
        end,
        %{}
      )

      await_response(:user_agent_set, [])
    end

    if_option :set_cookie do
      call(:set_cookie, "Network.setCookie", &Map.fetch!(&1, :set_cookie), %{})
      await_response(:cookie_set, [])
    end

    if_option :set_header do
      # call(:set_cookie, "Network.setCookie", &Map.fetch!(&1, :set_cookie), %{})
      # await_response(:cookie_set, [])
      call(
        :set_print_style_sheet,
        "Emulation.setEmulatedMedia",
        fn options ->
          %{
            "media" => "print"
          }
        end,
        %{}
      )

      await_response(:print_stylesheet_set, [])
    end

    if_option {:source_type, :html} do
      call(:get_frame_tree, "Page.getFrameTree", [], %{})
      await_response(:frame_tree, [{["frameTree", "frame", "id"], "frameId"}])
      call(:set_content, "Page.setDocumentContent", [:html, "frameId"], %{})
      await_response(:content_set, [])
      await_notification(:page_load_event, "Page.loadEventFired", [], [])
    end

    if_option {:source_type, :url} do
      call(:navigate, "Page.navigate", [:url], %{})

      await_response(:navigated, ["frameId"]) do
        case get_in(msg, ["result", "errorText"]) do
          nil ->
            :ok

          error ->
            {:error, error}
        end
      end

      await_notification(:frame_stopped_loading, "Page.frameStoppedLoading", ["frameId"], [])
    end

    if_option :evaluate do
      call(:evaluate, "Runtime.evaluate", [{"expression", [:evaluate, :expression]}], %{
        awaitPromise: true
      })

      await_response(:evaluated, []) do
        case get_in(msg, ["result", "exceptionDetails"]) do
          nil ->
            :ok

          error ->
            {:error, {:evaluate, error}}
        end
      end
    end
  end
end
