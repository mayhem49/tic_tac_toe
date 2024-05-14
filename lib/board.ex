defmodule Board do
  # TODO: remove symbols altogether

  @enforce_keys [:size, :state, :played_cells]
  defstruct [:size, :state, :played_cells]

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

    %__MODULE__{state: state, size: size, played_cells: 0}
  end

  def new(), do: new(@default_size)

  def play(%{state: state} = board, player, {x, y} = coord)
      when player in @players do
    case Map.fetch(state, coord) do
      :error ->
        {:error, "Invalid coordinate (#{x},#{y})"}

      {:ok, nil} ->
        new_state = Map.put(state, coord, player)
        new_board = %{board | state: new_state, played_cells: board.played_cells + 1}
        {:ok, new_board, game_status(new_board, player)}

      {:ok, _error} ->
        {:error, "Already played in coordinates (#{x},#{y}"}
    end
  end

  @doc """
  make this function to check irrespecitive of last played player
  then, rename is_winner? to check_winner
  """
  def is_winner?(%{size: size, state: state}, player)
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

  def game_status(%Board{} = board, player) do
    cond do
      is_winner?(board, player) -> :winner
      all_cells_played?(board) -> :draw
      true -> :running
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
    |> IO.inspect()
    |> TablePrint.print({size, size}, 7)
  end
end
