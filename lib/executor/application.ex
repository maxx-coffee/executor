defmodule Executor.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Starts a worker by calling: Executor.Worker.start_link(arg)
      # {Executor.Worker, arg}
      Executor.BlockSupervisor,
      Executor.RegisterTriggers,
      {ChromicPDF, chromic_pdf_opts()},
      Executor.DroidSupervisor
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Executor.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp chromic_pdf_opts do
    [
      # in milliseconds
      session_pool: [timeout: 60_000],
      session_pool: [init_timeout: 60_000]
    ]
  end
end
