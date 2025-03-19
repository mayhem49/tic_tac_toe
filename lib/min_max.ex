defmodule TicTacToe.MinMax do
  @players [:o, :x]
  def solve(%Board{} = board, maximizing_player) when maximizing_player in @players do
    {move, _score} = solve(board, maximizing_player, maximizing_player, 1)
    move
  end

  # board -> current state of the boarrd
  # current_player ->  player whose turn to play
  # https://www.neverstopbuilding.com/blog/minimax

  # current player wants to maximize/minimze
  # maximizing_player wants to minimize
  defp solve(%Board{} = board, maximizing_player, current_player, depth) do
    desired = if current_player == maximizing_player, do: :max, else: :min

    board
    |> Board.get_possible_moves()
    # |> IO.inspect(label: :possible)
    |> Enum.map(fn move ->
      {:ok, new_board, game_state} = Board.play(board, current_player, move)

      case game_state do
        :running ->
          {_, score} =
            solve(new_board, maximizing_player, alternate_player(current_player), depth + 1)

          {move, score}

        {:completed, :draw} ->
          {move, 0}

        {:completed, {:winner, _}} ->
          score = if desired == :max, do: 20 - depth, else: depth - 20
          {move, score}
      end
    end)
    # |> IO.inspect(label: :final)
    |> then(fn moves ->
      if desired == :max,
        do: Enum.max_by(moves, fn {_, score} -> score end),
        else: Enum.min_by(moves, fn {_, score} -> score end)
    end)
  end

  defp alternate_player(:o), do: :x
  defp alternate_player(:x), do: :o
end
