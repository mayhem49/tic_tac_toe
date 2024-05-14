defmodule GameTest do
  use ExUnit.Case
  alias TicTacToe.Game

  test "game started correctrly" do
    {instructions, _game} = Game.start(:sita, :ram)

    assert instructions == [
             create_instruction(:sita, :move)
           ]
  end

  test "making a move" do
    {_instructions, game} = Game.start(:sita, :ram)
    {instructions, _game} = Game.move(game, :sita, {1, 1})

    assert Enum.member?(instructions, create_instruction(:sita, {:move_success, {1, 1}}))
    assert Enum.member?(instructions, create_instruction(:ram, {:move_action, {1, 1}}))
    assert Enum.member?(instructions, create_instruction(:ram, :move))
  end

  test "cannot move on another's turn" do
    {_instructions, game} = Game.start(:sita, :ram)
    {instructions, _game} = Game.move(game, :ram, {3, 3})
    assert instructions == [create_instruction(:ram, :unauthorized_move)]

    {_inst, game} = Game.move(game, :sita, {1, 1})
    {instructions, _game} = Game.move(game, :sita, {3, 1})
    assert instructions == [create_instruction(:sita, :unauthorized_move)]
  end

  test "playing moves to next player" do
    {_instructions, game} = Game.start(:sita, :ram)

    {instructions, game} = Game.move(game, :sita, {1, 1})
    assert Enum.member?(instructions, create_instruction(:ram, :move))

    {instructions, _game} = Game.move(game, :ram, {2, 1})
    assert Enum.member?(instructions, create_instruction(:sita, :move))
  end

  test "winning result" do
    {_, game} =
      Game.start(:sita, :ram)

    {_, game} = Game.move(game, :sita, {1, 3})
    {_, game} = Game.move(game, :ram, {3, 2})
    {_, game} = Game.move(game, :sita, {2, 2})
    {_, game} = Game.move(game, :ram, {2, 3})
    {instructions, _game} = Game.move(game, :sita, {3, 1})

    Enum.member?(instructions, create_instruction(:sita, :winner))
    Enum.member?(instructions, create_instruction(:ram, :loser))
  end

  test "draw result" do
    {_, game} =
      Game.start(:sita, :ram)

    {_, game} = Game.move(game, :sita, {1, 1})
    {_, game} = Game.move(game, :ram, {1, 2})
    {_, game} = Game.move(game, :sita, {1, 3})
    {_, game} = Game.move(game, :ram, {2, 2})
    {_, game} = Game.move(game, :sita, {2, 3})
    {_, game} = Game.move(game, :ram, {3, 1})
    {_, game} = Game.move(game, :sita, {3, 2})
    {_, game} = Game.move(game, :ram, {3, 3})
    {instructions, _game} = Game.move(game, :sita, {2, 1})

    Enum.member?(instructions, create_instruction(:sita, :draw))
    Enum.member?(instructions, create_instruction(:ram, :draw))
  end

  test "cannot play after game end" do
    # TODO
  end

  defp create_instruction(player, notification),
    do: {:notify_player, player, notification}
end
