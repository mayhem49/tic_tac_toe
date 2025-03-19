defmodule Board do
  @enforce_keys [:size, :state, :played_cells, :last_played]
  defstruct @enforce_keys

  @players [:o, :x]

  def new(size) do
    state =
      1..size
      |> Enum.flat_map(fn x ->
        Enum.map(1..size, fn y ->
          {{x, y}, nil}
        end)
      end)
      |> Map.new()

    %__MODULE__{state: state, size: size, played_cells: 0, last_played: nil}
  end

  # can only play in empty cell
  def play(%Board{state: state} = board, player, {x, y} = cell)
      when player in @players do
    case Map.fetch(state, cell) do
      :error ->
        {:error, "Invalid cell (#{x},#{y})"}

      {:ok, nil} ->
        new_board = %{
          board
          | state: Map.put(state, cell, player),
            played_cells: board.played_cells + 1,
            last_played: cell
        }

        game_state = evaluate_game_state(new_board, player)
        {:ok, new_board, game_state}

      {:ok, _error} ->
        {:error, "Already played in cell (#{x},#{y}"}
    end
  end

  def evaluate_game_state(%Board{} = board, last_player) do
    # only the player who made the last move can be winner, so no need to check winner for opponent
    cond do
      is_winner_at_last_move?(board, last_player, board.last_played) -> {:completed, {:winner, last_player}}
      all_cells_played?(board) -> {:completed, :draw}
      true -> :running
    end
  end

  # The game can only be won by completing a row, column, or diagonal
  # that contains the played cell. Only check for these conditions.
  def is_winner_at_last_move?(%{size: size, state: state} = board, player, {row, col}) do
    # row
    row? = Enum.all?(1..size, fn y -> player == Map.get(state, {row, y}) end)

    # col
    col? = row? or Enum.all?(1..size, fn x -> player == Map.get(state, {x, col}) end)

    # diagonal 
      col? or (is_diagonal_cell?(board, {row, col}) and is_diagonal_completed?(board, player))
  end

  defp is_diagonal_cell?(%{size: size}, {row, col}) do
    # main-diagonal and anti-diagonal
    (row == col) or (row + col == size + 1)
  end

  defp is_diagonal_completed?(%{size: size, state: state}, player) do
    is_main_diagonal_completed? =
      Enum.all?(1..size, fn row ->
        player == Map.get(state, {row, row})
      end)

    # anti-diagonal
    is_main_diagonal_completed? or
      Enum.all?(1..size, fn row ->
        player == Map.get(state, {row, size + 1 - row})
      end)
  end

  # at the end of the match is_winner?() is called twice once by is_draw and once by the game module to check
  defp all_cells_played?(%Board{size: size} = board), do: board.played_cells == size * size

  def print(%Board{state: state, size: size} = _board) do
    1..size
    |> Enum.map(fn row ->
      1..size
      |> Enum.map(fn col ->
        state
        |> Map.get({row, col})
        |> to_string()
      end)
    end)
    |> TablePrint.print({size, size}, 7)
  end

  @doc """
  returns {:ok, move} if any move is possible(running game}
  else returns {:error, reason}
  """
  def minmax(board, maximizing_player) when maximizing_player in @players do
    {move, _score} = minmax(board, maximizing_player, maximizing_player, 1)
    move
  end

  # board -> current state of the boarrd
  # current_player ->  player whose turn to play
  # https://www.neverstopbuilding.com/blog/minimax

  # current player wants to maximize/minimze
  # maximizing_player wants to minimize
  defp minmax(%Board{} = board, maximizing_player, current_player, depth) do
    desired = if current_player == maximizing_player, do: :max, else: :min

    board
    |> get_possible_moves()
    #|> IO.inspect(label: :possible)
    |> Enum.map(fn move ->
      {:ok, new_board, game_state} = Board.play(board, current_player, move)

      case game_state do
        :running ->
          {_, score} = minmax(new_board, maximizing_player, alternate_player(current_player), depth + 1)
        {move, score}

        {:completed, :draw} ->
          {move, 0}

        {:completed, {:winner, _}} ->
          score = if desired == :max, do: 20 - depth, else: depth - 20
          {move, score}
      end
    end)
    #|> IO.inspect(label: :final)
    |> then(fn moves -> 
      if desired == :max,
        do: Enum.max_by(moves, fn {_, score} -> score end),
        else: Enum.min_by(moves, fn {_, score} -> score end)
    end
      )
  end

  defp get_possible_moves(%{state: state, size: size}) do
    1..size
    |> Enum.reduce([], fn row, acc ->
      1..size
      |> Enum.reduce(acc, fn col, acc ->
        case Map.get(state, {row, col}) do
          nil ->
            [{row, col} | acc]

          _ ->
            acc
        end
      end)
    end)
  end

  defp alternate_player(:o), do: :x
  defp alternate_player(:x), do: :o

  ## for testing purpose
  # def test() do
  #   {:ok, b, _} = Board.new(3)
  #   |> test_play(:o, {1,1})
  #   |> test_play(:x, {1,2})
  #   |> test_play(:o, {2,1})
  #   b
  # end

  # defp test_play({:ok, board, _}, player, cell) do
  #   Board.play(board, player, cell)
  # end

  # defp test_play(board, player, cell) do
  #   Board.play(board, player, cell)
  # end
end
