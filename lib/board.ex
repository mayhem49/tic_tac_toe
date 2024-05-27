defmodule Board do
  # TODO: remove symbols altogether

  @enforce_keys [:size, :state, :played_cells, :status]
  defstruct [:size, :state, :played_cells, :status]

  @players [:o, :x]
  @default_size 3

  # TODO: create a nxn board 
  def new(size) do
    state =
      1..size
      |> Enum.flat_map(fn x ->
        Enum.map(1..size, fn y ->
          {{x, y}, nil}
        end)
      end)
      |> Map.new()

    %__MODULE__{state: state, size: size, played_cells: 0, status: :running}
  end

  def new(), do: new(@default_size)

  def play(%{state: state} = board, player, {x, y} = coord)
      when player in @players do
    case Map.fetch(state, coord) do
      :error ->
        {:error, "Invalid coordinate (#{x},#{y})"}

      {:ok, nil} ->
        new_state = Map.put(state, coord, player)
        # WARN: new_board is in invalid state since it has incorrect game_status, solution?
        new_board = %{board | state: new_state, played_cells: board.played_cells + 1}
        game_status = evaluate_game_status(new_board)
        {:ok, %{new_board | status: game_status}}

      {:ok, _error} ->
        {:error, "Already played in coordinates (#{x},#{y}"}
    end
  end

  defp is_winner?(%{size: size, state: state}, player)
       when player in @players do
    # won if three horizontal, vertical or diagonal elemetns are of same player
    # box indexing starts from 1

    check_horizontal_and_vertical = fn ->
      1..size
      |> Enum.any?(fn i ->
        # check all row of ith column and all column of ith row
        row_winner =
          1..size
          |> Enum.all?(fn col -> player == Map.get(state, {i, col}) end)

        row_winner ||
          1..size
          |> Enum.all?(fn row -> player == Map.get(state, {row, i}) end)
      end)
    end

    check_diagonal = fn ->
      diagonal_winner =
        1..size
        |> Enum.all?(fn row ->
          player == Map.get(state, {row, row})
        end)

      # anti-diagonal-winner
      diagonal_winner ||
        1..size
        |> Enum.all?(fn row ->
          player == Map.get(state, {row, size + 1 - row})
        end)
    end

    check_horizontal_and_vertical.() || check_diagonal.()
  end

  # at the end of the match is_winner?() is called twice once by is_draw and once by the game module to check
  defp all_cells_played?(%Board{size: size} = board), do: board.played_cells == size * size

  # @doc """ evaluates the current status of the game, using `state` field.
  # Used to evalute `status` field of the struct.
  # """
  defp evaluate_game_status(%Board{} = board) do
    [ref_player, _] = @players

    cond do
      is_winner?(board, ref_player) -> {:winner, ref_player}
      is_winner?(board, alternate_player(ref_player)) -> {:winner, alternate_player(ref_player)}
      all_cells_played?(board) -> :draw
      true -> :running
    end
  end

  @doc """
   status of the game w.r.t `ref_player`>.
  """
  def game_status(%Board{status: status}, ref_player) when ref_player in @players do
    case status do
      {:winner, ^ref_player} -> :winner
      {:winner, _alternate_player} -> :loser
      :draw -> :draw
      :running -> :running
    end
  end

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

  defp minmax_get_score(board, maximizing_player) do
    case game_status(board, maximizing_player) do
      :winner -> 20
      :loser -> -20
      :draw -> 0
    end
  end

  @doc """
  returns {:ok, move} if any move is possible(running game}
  else returns {:error, reason}
  """
  def minmax(board, maximizing_player) when maximizing_player in @players do
    {new_board, _score} = minmax(board, maximizing_player, maximizing_player)

    # todo: make minmax function return move instead of new board
    find_move(board, new_board)
  end

  defp find_move(board, new_board) do
    1..board.size
    |> Enum.find_value(fn row ->
      col =
        1..board.size
        |> Enum.find(fn col ->
          Map.get(board.state, {row, col}) == nil &&
            Map.get(new_board.state, {row, col}) != nil
        end)

      col && {row, col}
    end)
  end

  # board -> current state of the boarrd
  # current_player ->  player whose turn to play
  defp minmax(%Board{status: :running} = board, maximizing_player, current_player) do
    max_value = -20
    min_value = 20

    {desired, initial_value} =
      if current_player == maximizing_player, do: {:max, max_value}, else: {:min, min_value}

    board
    |> get_possible_moves()
    |> Enum.reduce(
      {board, initial_value},
      fn move, {curr_board, minmax_value} ->
        {:ok, new_board} = Board.play(board, current_player, move)

        # print(new_board)

        {_board, score} = minmax(new_board, maximizing_player, alternate_player(current_player))

        # IO.puts("")
        # IO.puts("")
        # print(new_board)

        cond do
          desired == :max && score >= minmax_value ->
            # IO.inspect(:max)
            {new_board, score}

          desired == :min && score <= minmax_value ->
            # IO.inspect(:min)
            {new_board, score}

          true ->
            # IO.inspect(:no_change)
            {curr_board, minmax_value}
        end
      end
    )
  end

  defp minmax(%Board{} = board, maximizing_player, _current_player) do
    {board, minmax_get_score(board, maximizing_player)}
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

  def random do
    {:ok, board} =
      Board.new()
      |> test_play(:o, {3, 2})
      |> test_play(:x, {1, 1})
      |> test_play(:o, {1, 2})
      |> test_play(:x, {2, 2})
      |> test_play(:o, {1, 3})

    # |> test_play(:x, {2, 3})
    # |> test_play(:o, {3, 3})

    IO.inspect("intitial_board")
    print(board)
    board
  end

  defp test_play({:ok, board}, player, coord) do
    Board.play(board, player, coord)
  end

  defp test_play(board, player, coord) do
    Board.play(board, player, coord)
  end
end
