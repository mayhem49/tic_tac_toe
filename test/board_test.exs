defmodule BoardTest do
  use ExUnit.Case

  test "creates  a correct 3x3 board" do
    board = Board.new()
    state = board.state
    assert Map.has_key?(state, {1, 1})
    assert Map.has_key?(state, {3, 3})
    assert Map.has_key?(state, {2, 3})

    assert Map.fetch(state, {0, 0}) == :error
    assert Map.fetch(state, {2, 0}) == :error
    assert Map.fetch(state, {0, 2}) == :error
    assert Map.fetch(state, {4, 0}) == :error
    assert Map.fetch(state, {0, 4}) == :error
  end

  test "plays in empty cells only" do
    board = Board.new()

    {:ok, board, _game_status} =
      board
      |> play(:o, {1, 1})
      |> play(:x, {2, 1})
      |> play(:o, {3, 3})

    assert Map.get(board.state, {1, 1}) == :o
    assert Map.get(board.state, {2, 1}) == :x
    assert Map.get(board.state, {3, 3}) == :o
    assert Map.get(board.state, {2, 3}) == nil
    assert Map.get(board.state, {1, 2}) == nil

    # cannot play on already played board
    assert {:error, _message} = Board.play(board, :x, {1, 1})
    assert {:error, _message} = Board.play(board, :x, {3, 3})

    # cannot play on invalid cell
    assert {:error, _message} = Board.play(board, :x, {4, 0})
    assert {:error, _message} = Board.play(board, :x, {0, 4})
  end

  test "don't allow invalid players to play" do
    board = Board.new()

    assert_raise FunctionClauseError, fn -> Board.play(board, :rr, {1, 2}) end
  end

  test "returns correct game_status" do
    # check anti diagonal matched winner
    {:ok, _board, game_status} =
      Board.new()
      |> play(:o, {1, 3})
      |> play(:x, {3, 2})
      |> play(:o, {2, 2})
      |> play(:x, {2, 3})
      |> play(:o, {3, 1})

    assert game_status == :winner

    # check diagonal winner 
    {:ok, _board, game_status} =
      Board.new()
      |> play(:o, {3, 1})
      |> play(:x, {2, 2})
      |> play(:o, {1, 3})
      |> play(:x, {1, 1})
      |> play(:o, {2, 3})
      |> play(:x, {3, 3})

    # check anti diagonal matched winner
    assert game_status == :winner

    # check horizontal matched winner
    {:ok, _board, game_status} =
      Board.new()
      |> play(:o, {1, 1})
      |> play(:x, {3, 3})
      |> play(:o, {2, 2})
      |> play(:x, {2, 3})
      |> play(:o, {2, 1})
      |> play(:x, {1, 3})

    assert game_status == :winner

    # check game running stae
    {:ok, _board, game_status} =
      Board.new()
      |> play(:o, {1, 1})
      |> play(:x, {3, 2})
      |> play(:o, {2, 2})
      |> play(:x, {1, 2})
      |> play(:o, {2, 3})
      |> play(:x, {1, 3})
      |> play(:o, {3, 1})
      |> play(:x, {2, 1})

    assert game_status == :running

    # check game draw
    {:ok, _board, game_status} =
      Board.new()
      |> play(:o, {1, 1})
      |> play(:x, {1, 2})
      |> play(:o, {1, 3})
      |> play(:x, {2, 2})
      |> play(:o, {2, 3})
      |> play(:x, {3, 1})
      |> play(:o, {3, 2})
      |> play(:x, {3, 3})
      |> play(:o, {2, 1})

    assert game_status == :draw
  end

  defp play({:ok, board, _game_status}, player, coord) do
    Board.play(board, player, coord)
  end

  defp play(board, player, coord) do
    Board.play(board, player, coord)
  end
end
