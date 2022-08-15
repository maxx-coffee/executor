defmodule Executor do
  use Executor.Workflow

  trigger("test")
  trigger("more_test")

  steps do
    call "first" do
      inport_options = %{
        message: trigger_message()
      }

      inport(inport_options)

      component(fn _resp ->
        {:ok, "test"}
      end)

      next("third")
      error("error_state")
    end

    call "second" do
      next("third")

      IO.inspect("runnign second")
    end

    call "third" do
      inport(fn _resp ->
        %{
          params: "hi"
        }
      end)

      IO.inspect("runnign third")
    end

    call "error_state" do
      IO.inspect("error")
    end
  end
end
