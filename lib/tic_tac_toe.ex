defmodule TicTacToe do
  use Application
  @impl true
  def start(_start_type, _start_args) do
    children = [
      {Registry, keys: :unique, name: TicTacToe.Registry},
      TicTacToe.GameSupervisor
    ]

    # restart all child process when any of them terminates
    return_value = Supervisor.start_link(children, strategy: :one_for_all)

    TicTacToe.GameServer.start_game(:game, {:player, :interactive}, {:bot, :autoplay})
    Process.sleep(200)
    return_value
  end

  def service_name(service_id) do
    {:via, Registry, {TicTacToe.Registry, service_id}}
  end

  def observe() do
    Mix.ensure_application!(:wx)
    Mix.ensure_application!(:runtime_tools)
    Mix.ensure_application!(:observer)
    :observer.start()
  end
end
