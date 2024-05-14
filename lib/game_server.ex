defmodule TicTacToe.GameServer do
  use GenServer

  alias TicTacToe.{Game, Player}
  ## supervisor related stuff
  def start_game(game_id, player1, player2) do
    IO.puts("GameServer.start_game")

    DynamicSupervisor.start_child(
      TicTacToe.GameSupervisor,
      {TicTacToe.SingleGameSupervisor, {game_id, player1, player2}}
    )
  end

  def start_link({game_id, player1, player2}) do
    IO.puts("GameServer.start_link")

    GenServer.start_link(__MODULE__, {:game_id, player1, player2},
      name: TicTacToe.service_name(game_id)
    )
  end

  def move(game_id, player_id, {_, _} = move) do
    GenServer.call(TicTacToe.service_name(game_id), {:move, player_id, move})
  end

  ## callback
  @impl true
  def init({game_id, player1, player2}) do
    state = %{game: nil, game_id: game_id}

    {:ok,
     Game.start(player1, player2)
     |> handle_game_instructions(state)}
  end

  @impl true
  def handle_call({:move, player_id, {_, _} = coord}, _from, state) do
    state =
      state.game
      |> Game.move(player_id, coord)
      |> handle_game_instructions(state)

    {:reply, :ok, state}
  end

  defp handle_game_instructions({instructions, game}, state) do
    Enum.each(instructions, &handle_instruction(&1))
    %{state | game: game}
  end

  defp handle_instruction({:notify_player, player, message_payload}) do
    Player.notify(player, message_payload)
  end
end
