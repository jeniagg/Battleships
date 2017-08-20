defmodule Battleships.Games do
    @moduledoc """
    The module represents the game server.
    It is responsible for games initiatives.
    """

    use GenServer
    # player -> key: name , value:  {pid, ships}

    defstruct [:pid, players: Map.new(), current_player: nil]
    
    def start(players) do
        GenServer.start(__MODULE__, [players], [])
    end

    def start_link(players) do
        GenServer.start_link(__MODULE__, [players], []) 
    end

    def make_move(game, player_name, move) do
        GenServer.call(game, {:make_move, player_name, move})
    end

    # player: name => pid
    def init([players]) do
        # Battleships.Server.set_in_game(players, self())
        set_in_game(players, self())
        {player_name, player} = hd(Map.to_list(players))
        {:ok, %Battleships.Games{pid: self(), players: initialize_state(players), current_player: player_name}}
    end

    # players: name => pid
    defp initialize_state(players) do
        Enum.reduce(players, Map.new(), 
            fn({player_name, player}, acc) ->
                %{acc | player_name => %Battleships.GamePlayerData{player: player}}
            end)
    end
    
    def inspect_state(game_pid) do
        GenServer.call(game_pid, :inspect_state)
    end

    def create_board(game, ships, player_name) do
        GenServer.call(game, {:create_board, ships, player_name})
    end

    def handle_call(:inspect_state, _, state) do
        {:reply, state, state}
    end

    def handle_call({:create_board, ships, player_name}, _, state) do
        ships = Battleships.GamePlayerData.generate_ships(ships)
        {:ok, player_data} = Map.fetch(state.players, player_name)
        {new_player_data, reply} = update_ships(player_data, ships)
        new_state = %{state | players: Map.put(state.players, player_name, new_player_data)}
        {:reply, reply, new_state}
    end

    # TODO: make the game not die, but ask for a new one, the two players
    def handle_call({:make_move, player_name, move}, _, state) do
        valid_move = validate_move(player_name, move, state.current_player)
        other_player = get_other_player(state.current_player, state)
        other_player_ships = get_player_ships(player_name, state)
        {reply, new_ships} = apply_move(valid_move, move, other_player_ships)
        game_end = check_game_end(new_ships, state.players, state.current_player)
        new_state = update_move_state(reply, other_player, new_ships, state)
        case game_end do
            :continue -> {:reply, reply, new_state}
            :game_end -> {:stop, :normal, new_state}
        end
    end

    defp update_move_state({:error, _}, _, _, state), do: state
    defp update_move_state(:ok, other_player, new_ships, state) do
        other_player_data = get_player_data(other_player, state)
        %{state | current_player: other_player,
            players: Map.put(state.players, other_player, update_player_ships(other_player_data, new_ships))
        }
    end

    defp check_game_end([], players, current_player) do
        Enum.reduce(players, 
            fn({player_name, player_data}) ->
                Battleships.Player.match_end(player_data.player, {:winner, current_player}) 
            end
        )
        :game_end
    end

    defp check_game_end(_, _, _), do: :continue

    defp apply_move(reply = {:error, msg}, _, ships), do: {reply, ships}
    defp apply_move(:ok, move, ships) do
        Battleships.GamePlayerData.apply_move(move, ships)
    end

    defp get_other_player(current_player, state) do
        players = Map.keys(state.players)
        [other_player] = List.delete(players, current_player)
        other_player
    end

    defp get_player_data(player_name, state) do
        {:ok, player_data} = Map.fetch(state.players, player_name)
        player_data
    end

    defp get_player_ships(player_name, state) do
        player_data = get_player_data(player_name, state)
        Battleships.GamePlayerData.get_ships(player_data)
    end

    defp update_player_ships(player_data, new_ships), do: %{player_data | ships: new_ships}

    defp validate_move(player_name, move, current_player) do
        valid_player = validate_player(player_name, current_player)
        valid_position = validate_position(Battleships.GamePlayerData.is_valid(move))
        validate_move(valid_player, valid_position)
    end

    defp validate_player(player_name, player_name), do: :ok
    defp validate_player(_player_name, _current_player), do: {:error, "It's not your turn."}

    defp validate_position(true), do: :ok
    defp validate_position(false), do: {:error, "Wrong move"}
    
    defp validate_move(:ok, :ok), do: :ok
    defp validate_move(:ok, reply), do: reply
    defp validate_move(reply, :ok), do: reply
    defp validate_move(reply, _), do: reply

    defp update_ships(player, reply = {:error, msg}), do: {player, reply}
    defp update_ships(player_data, {:ok, ships}) do
        new_player_data = %{player_data | ships: ships}
        {new_player_data, :ok}
    end

    defp set_in_game(players, game) do
        Enum.reduce(players, :ok,
            fn({_, player}, _) ->
                Battleships.Player.set_in_game(player, game)
            end)
    end

    def child_spec(args) do
        %{
            id: Battleships.Games,
            start: {Battleships.Games, :start_link, [args]},
            restart: :transient,
            shutdown: 5000,
            type: :worker       
        }
    end
    

end