defmodule TicTacToe.GameSupervisor do
  use DynamicSupervisor

  def start_link(init_arg) do
    IO.puts("dynamic  GameSupervisor")
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end

defmodule TicTacToe.SingleGameSupervisor do
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg)
  end

  @impl true
  # def init([game_id, player1, player2]) do
  def init({game_id, {player1, player1_type}, {player2, player2_type}}) do
    children = [
      {TicTacToe.Player, {game_id, player1, player1_type, :o}},
      {TicTacToe.Player, {game_id, player2, player2_type, :x}},
      {TicTacToe.GameServer, {game_id, player1, player2}}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
