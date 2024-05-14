defmodule TicTacToe.Player do
  use GenServer

  alias TicTacToe.{GameServer}

  def notify(player_id, instruction) do
    GenServer.cast(TicTacToe.service_name(player_id), instruction)
  end

  # TicTacToe.GameServer.start_game :game, :p1, :p2

  def child_spec({_, player_id, _, _} = arg) do
      %{
      id: player_id,
      start: {__MODULE__, :start_link, [arg]}
    }
  end

  def start_link({game_id, player_id, player_type, symbol}) do
    IO.puts("player.start_link #{player_id}")

    GenServer.start_link(__MODULE__, {game_id, player_id, player_type, symbol},
      name: TicTacToe.service_name(player_id)
    )
  end

  @impl true
  def init({game_id, player_id, player_type, symbol}) when symbol in [:o, :x] do
    {:ok,
     %{
       game_id: game_id,
       player_id: player_id,
       player_type: player_type,
       symbol: symbol,
       alternate_symbol: alternate_symbol(symbol),
       board: Board.new()
     }}
  end

  @impl true
  def handle_cast(:move, state) do
    print_message(state, "move")
    %{game_id: game_id, player_id: player_id} = state

    case state.player_type do
      :interactive ->
        Board.print(state.board)
        move = read_move(state)
        GameServer.move(game_id, player_id, move)
    end

    {:noreply, state}
  end

  @impl true
  def handle_cast(:winner, state) do
    print_message(state, "you win!")
    {:noreply, state}
  end

  @impl true
  def handle_cast(:loser, state) do
    print_message(state, "you lose")
    {:noreply, state}
  end

  @impl true
  def handle_cast(:draw, state) do
    print_message(state, "game draw")
    {:noreply, state}
  end

  @impl true
  def handle_cast(:unauthorized_move, state) do
    print_message(state, "unauthorized move")
    {:noreply, state}
  end

  @impl true
  def handle_cast({:move_action, {x, y} = coord}, state) do
    {:ok, board, _game_status} = Board.play(state.board, state.symbol, coord)
    print_message(state, "opponent_move(#{x}, #{y})")

    {:noreply, %{state | board: board}}
  end

  @impl true
  def handle_cast({:move_success, {x, y} = coord}, state) do
    {:ok, board, _game_status} = Board.play(state.board, state.alternate_symbol, coord)
    print_message(state, "move success(#{x}, #{y})")
    {:noreply, %{state | board: board}}
  end

  @impl true
  def handle_cast({:move_error, reason}, state) do
    print_message(state, "move_error: #{reason}")
    {:noreply, state}
  end

  defp read_move(state) do
    IO.gets("#{state.player_id} move(x,y): ")
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.map(&String.to_integer(&1))
    |> List.to_tuple()
  end

  defp print_message(state, message) do
    IO.puts("#{state.player_id}: #{message}")
  end

  defp alternate_symbol(:o), do: :x
  defp alternate_symbol(:x), do: :o
end
