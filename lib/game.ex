defmodule TicTacToe.Game do
  alias __MODULE__

  defstruct [:board, :player_symbols, :current_player, :alternate_player, :instructions, :state]

  # A game is an instance that handles all the game logic.
  # It allows following actions: `move`
  # keys
  # board: 
  # player_symbols: maps the `player` key to its corresponding symbol (`o` or `x`)
  # current playe:
  # alternate_player:
  # instructions: mechanism to notify players of action happend and also request action
  # state: :running, {:completed, result}
  # the current state of the game

  # multiple guards substitutes a charin of `or` guards
  # serves as documentation also I guess
  defguard is_valid_instruction_atom(instruction)
           when instruction in [:move, :winner, :loser, :draw, :unauthorized_move]

  defguard is_valid_instruction_tuple(instruction)
           when tuple_size(instruction) == 2 and
                  elem(instruction, 0) in [:move_success, :move_error, :move_action]

  defguard is_valid_instruction(instruction)
           when is_valid_instruction_atom(instruction) or is_valid_instruction_tuple(instruction)

  def start(player1, player2, size \\ 3) do
    game = %Game{
      board: Board.new(size),
      player_symbols: %{player1 => :o, player2 => :x},
      current_player: player1,
      alternate_player: player2,
      instructions: [],
      state: :running
    }

    game
    |> notify_current_player(:move)
    |> return_intructions_and_game()
  end

  # ^^
  def move(
        %Game{current_player: current_player, state: :running} = game,
        current_player,
        {_, _} = coord
      ) do
    current_symbol = Map.get(game.player_symbols, current_player)

    game =
      case Board.play(game.board, current_symbol, coord) |> IO.inspect() do
        {:ok, new_board, game_state} ->
          %{game | board: new_board, state: game_state}
          |> notify_current_player({:move_success, coord})
          |> notify_alternate_player({:move_action, coord})
          |> process_game_state()

        {:error, reason} ->
          game
          |> notify_current_player({:move_error, reason})
          |> notify_current_player(:move)
      end

    return_intructions_and_game(game)
  end

  # don't allow to move when player other than `current_player` tries to play
  def move(game, player, _coord) do
    game
    |> notify_player(player, :unauthorized_move)
    |> return_intructions_and_game()
  end

  # ^^
  defp process_game_state(game) do
    case game.state do
      :running ->
        game
        |> notify_alternate_player(:move)
        |> switch_turn()

      # TODO: may be switch turn at the start? since changing state in 
      # multiple places can make the game more preone to bug on code change

      {:completed, result} ->
        case result do
          :draw ->
            game |> notify_both_players(:draw)

          # guard is just for safety since only current player can be winner
          # TODO: maybe make curr and alt player nil? after game completion
          {:winner, winner} ->
            winner_symbol = Enum.find_value(game.player_symbols, 
              fn {player, symbol} -> if player == game.current_player, do: symbol end)

            if winner_symbol != winner, do: raise("Only currrent player can be winner")
            game
            |> notify_current_player(:winner)
            |> notify_alternate_player(:loser)
        end
    end
  end

  defp switch_turn(game),
    do: %Game{game | current_player: game.alternate_player, alternate_player: game.current_player}

  defp notify_both_players(game, notification) do
    game
    |> notify_player(game.current_player, notification)
    |> notify_player(game.alternate_player, notification)
  end

  defp notify_current_player(game, notification) when is_valid_instruction(notification),
    do: notify_player(game, game.current_player, notification)

  defp notify_alternate_player(game, notification),
    do: notify_player(game, game.alternate_player, notification)

  defp notify_player(game, player, notification),
    do: %Game{game | instructions: [{:notify_player, player, notification} | game.instructions]}

  defp return_intructions_and_game(game),
    do: {Enum.reverse(game.instructions), %{game | instructions: []}}
end
