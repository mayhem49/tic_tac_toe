defmodule BoardTest do
  use ExUnit.Case
  doctest Board

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

    board =
      board
      |> Board.play({1, 1}, :o)
      |> Board.play({2, 1}, :x)
      |> Board.play({3, 3}, :o)

    assert Map.get(board.state, {1, 1}) == :o
    assert Map.get(board.state, {2, 1}) == :x
    assert Map.get(board.state, {3, 3}) == :o
    assert Map.get(board.state, {2, 3}) == nil
    assert Map.get(board.state, {1, 2}) == nil

    # cannot play on already played board
    assert {:error, _message} = Board.play(board, {1, 1}, :x)
    assert {:error, _message} = Board.play(board, {3, 3}, :x)

    # cannot play on invalid cell
    assert {:error, _message} = Board.play(board, {4, 0}, :x)
    assert {:error, _message} = Board.play(board, {0, 4}, :x)
  end

  test "don't allow invalid players to play" do
    board = Board.new()

    assert_raise FunctionClauseError, fn -> Board.play(board, {1, 2}, :rr) end
  end

  test "checks winner correctly" do
    # check anti diagonal matched winner
    board =
      Board.new()
      |> Board.play({1, 3}, :o)
      |> Board.play({3, 2}, :x)
      |> Board.play({2, 2}, :o)
      |> Board.play({2, 3}, :x)
      |> Board.play({3, 1}, :o)

    assert Board.is_winner?(board, :o)
    assert Board.is_winner?(board, :x) == false

    # check diagonal winner 
    board =
      Board.new()
      |> Board.play({3, 1}, :o)
      |> Board.play({2, 2}, :x)
      |> Board.play({1, 3}, :o)
      |> Board.play({1, 1}, :x)
      |> Board.play({2, 3}, :o)
      |> Board.play({3, 3}, :x)

    # check anti diagonal matched winner
    assert Board.is_winner?(board, :x)
    assert Board.is_winner?(board, :o) == false

    # check horizontal matched winner
    board =
      Board.new()
      |> Board.play({1, 1}, :o)
      |> Board.play({3, 3}, :x)
      |> Board.play({2, 2}, :o)
      |> Board.play({2, 3}, :x)
      |> Board.play({2, 1}, :o)
      |> Board.play({1, 3}, :x)

    assert Board.is_winner?(board, :x)
    assert Board.is_winner?(board, :o) == false

    # check no winnners
    board =
      Board.new()
      |> Board.play({1, 1}, :o)
      |> Board.play({3, 2}, :x)
      |> Board.play({2, 2}, :o)
      |> Board.play({1, 2}, :x)
      |> Board.play({2, 3}, :o)
      |> Board.play({1, 3}, :x)
      |> Board.play({3, 1}, :o)
      |> Board.play({2, 1}, :x)

    assert Board.is_winner?(board, :o) == false
    assert Board.is_winner?(board, :x) == false
  end
end
