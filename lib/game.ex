defmodule TicTacToe.Game do
  alias __MODULE__

  defstruct [:board, :player_symbols, :current_player, :alternate_player, :instructions, :status]

  def start(player1, player2, size \\ 3) do
    game = %Game{
      board: Board.new(size),
      player_symbols: %{player1 => :o, player2 => :x},
      current_player: player1,
      alternate_player: player2,
      instructions: [],
      status: :running
    }

    game
    |> notify_current_player(:move)
    |> return_intructions_and_game()
  end

  def move(%Game{current_player: current_player} = game, current_player, {_, _} = coord) do
    current_symbol = Map.get(game.player_symbols, current_player)

    game =
      case Board.play(game.board, current_symbol, coord) do
        {:ok, board, game_status} ->
          %{game | board: board}
          |> notify_current_player({:move_success, coord})
          |> notify_alternate_player({:move_action, coord})
          |> manage_game_status(game_status)

        {:error, reason} ->
          game
          |> notify_current_player({:move_error, reason})
          |> notify_current_player(:move)
      end

    return_intructions_and_game(game)
  end

  def move(game, player, _coord) do
    game
    |> notify_player(player, :unauthorized_move)
    |> return_intructions_and_game()
  end

  defp manage_game_status(game, status) do
    case status do
      :winner ->
        game
        |> notify_current_player(:winner)
        |> notify_alternate_player(:loser)

      :draw ->
        game |> notify_both_players(:draw)

      :running ->
        game
        |> notify_alternate_player(:move)
        |> switch_turn()
    end
  end

  defp switch_turn(game),
    do: %Game{game | current_player: game.alternate_player, alternate_player: game.current_player}

  defp notify_both_players(game, notification) do
    game
    |> notify_player(game.current_player, notification)
    |> notify_player(game.alternate_player, notification)
  end

  defp notify_current_player(game, notification),
    do: notify_player(game, game.current_player, notification)

  defp notify_alternate_player(game, notification),
    do: notify_player(game, game.alternate_player, notification)

  defp notify_player(game, player, notification),
    do: %Game{game | instructions: [{:notify_player, player, notification} | game.instructions]}

  defp return_intructions_and_game(game),
    do: {Enum.reverse(game.instructions), %{game | instructions: []}}
end
