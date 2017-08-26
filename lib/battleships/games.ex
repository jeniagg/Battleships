defmodule Battleships.Games do
    @moduledoc """
    The module represents the game server.
    It is responsible for games initiatives.
    """

    use GenServer

    # player -> key: name , value:  {pid, ships}
    defstruct [:pid, players: Map.new(), current_player: nil, uuid: nil]

    def start(players, uuid) do
        GenServer.start(__MODULE__, [players, uuid], name: {:global, uuid})
    end

    def start_link(players, uuid) do
        GenServer.start_link(__MODULE__, [players, uuid], name: {:global, uuid}) 
    end
    
    def init([players, uuid]) do
        player_name = Enum.random(players)
        IO.inspect(player_name, label: "The first player is: ")
        {:ok, %Battleships.Games{pid: self(), players: initialize_state(players), current_player: player_name, uuid: uuid}}
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

    ########################### API FUNCTIONS ###########################

    @doc ~S"""
    Kill the game process normally

    Arguments
        uuid -> The unique uuid of the game
 
    Examples
        iex> Battleships.Games.stop("7df2eec2-1ddd-42c3-aa1b-1e8b52e3ea31")
        :ok
    """
    def stop(uuid) do
      GenServer.call({:global, uuid}, :stop)
    end

    @doc ~S"""
    Make move in the game through the Game API

    Arguments
        uuid -> The unique uuid of the game
        player_name -> the name of the player, which makes the move
        move -> {x,y} coordinates of the move
 
    Examples
        iex> Battleships.Games.make_move("7df2eec2-1ddd-42c3-aa1b-1e8b52e3ea31", "a", {1,2})
        {:error, "It's not your turn."}

        iex> Battleships.Games.make_move("7df2eec2-1ddd-42c3-aa1b-1e8b52e3ea31", "b", {1,2})
        :no_hit

        iex> Battleships.Games.make_move("7df2eec2-1ddd-42c3-aa1b-1e8b52e3ea31", "b", {1,2})
        :hit
    """
    def make_move(uuid, player_name, move) do
        GenServer.call({:global, uuid}, {:make_move, player_name, move})
    end

    @doc ~S"""
    State of the present game

    Arguments: 
        uuid -> the unique uuid of the game

    Examples

        iex> Battleships.Games.inspect_state("c5cfe2a9-0b20-42ff-b94d-e93643209aa6")
        %Battleships.Games{current_player: "pesho", pid: :global.whereis_name("c5cfe2a9-0b20-42ff-b94d-e93643209aa6"),players: %{"gosho" => %Battleships.GamePlayerData{player: nil, ships: []}, "pesho" => %Battleships.GamePlayerData{player: nil, ships: []}}, uuid: "c5cfe2a9-0b20-42ff-b94d-e93643209aa6"}
    """
    def inspect_state(uuid) do
        GenServer.call({:global, uuid}, :inspect_state)
    end

    @doc ~S"""
    Create a board for the given game for the given player. 

    Arguments:
        player_name -> the name of the player
        ships -> the ships of the player

    Examples
        iex> Battleships.Games.create_board("4de61b65-a28b-4083-b370-95f7e19fe748",[{:vertical, {6,2}, 2}, {:horizontal, {1,3}, 3}, {:horizontal, {7,8}, 2}, {:vertical, {3,7}, 5}, {:vertical, {5,6}, 2}], "pesho")
        :ok

        iex> Battleships.Games.create_board("4de61b65-a28b-4083-b370-95f7e19fe748",[{:vertical, {6,2}, 13}, {:horizontal, {1,3}, 3}, {:horizontal, {7,8}, 2}, {:vertical, {3,7}, 5}, {:vertical, {5,6}, 2}], "pesho")
        {:error, "The board can't be created! There are wrong coordinates!"}

        iex> Battleships.Player.create_board("4de61b65-a28b-4083-b370-95f7e19fe748",[{:vertical, {6,2}, 2}, {:horizontal, {1,3}, 3}], "pesho")
        {:error, "Wrong number of ships! They must be 5!"}
    """
    def create_board(uuid, ships, player_name) do
        GenServer.call({:global, uuid}, {:create_board, ships, player_name})
    end


    ########################### HANDLE CALL ###########################
    
    def handle_call(:stop, _, state) do
        {:stop, :normal, :ok, state}
    end

    def handle_call(:inspect_state, _, state) do
        {:reply, state, state}
    end

    def handle_call({:create_board, ships, player_name}, _, state) do
        {:ok, player_data} = Map.fetch(state.players, player_name)
        ships = case Battleships.GamePlayerData.get_ships(player_data) do
            [] -> Battleships.GamePlayerData.generate_ships(ships, player_name)
            _ -> {:error, "This player already created his board!"}
        end
        {new_player_data, reply} = update_ships(player_data, ships)
        new_state = %{state | players: Map.put(state.players, player_name, new_player_data)}
        {:reply, reply, new_state}
    end

    def handle_call({:make_move, player_name, move}, _, state) do
        valid_move = validate_move(player_name, move, state)
        other_player = get_other_player(state.current_player, state)
        other_player_ships = get_player_ships(other_player, state)
        {reply, new_ships} = apply_move(valid_move, move, other_player_ships)
        game_end = check_game_end(new_ships, state.players, state.current_player)
        case game_end do
            :continue -> 
                new_state = update_move_state(reply, other_player, new_ships, state)
                {:reply, reply, new_state}
            :game_end -> 
                {:stop, :normal, :game_end, state}
        end
    end

    
    ########################### PRIVATE FUNCTIONS ###########################

    defp update_move_state({:error, _}, _, _, state), do: state
    defp update_move_state(:no_hit, other_player, _, state), do: %{state | current_player: other_player}
    defp update_move_state(:hit, other_player, new_ships, state) do
        other_player_data = get_player_data(other_player, state)
        %{state | current_player: other_player,
            players: Map.put(state.players, other_player, update_player_ships(other_player_data, new_ships))
        }
    end

    defp check_game_end([], players, current_player) do
        players_name = Map.keys(players)
        List.foldl(players_name, [], 
            fn(player_name, _) ->
                Battleships.Player.match_end(player_name, {:winner, current_player})
            end)
        :game_end
    end

    defp check_game_end(_, _, _), do: :continue

    defp apply_move(reply = {:error, _}, _, ships), do: {reply, ships}
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

    defp validate_move(player_name, move, state) do
        valid_player = validate_player(player_name, state.current_player)
        valid_position = validate_position(Battleships.GamePlayerData.is_valid(move))
        validate_move(valid_player, valid_position)
    end

    defp validate_player(player_name, current_player) when player_name == current_player, do: :ok
    defp validate_player(_, _), do: {:error, "It's not your turn."}

    defp validate_position(true), do: :ok
    defp validate_position(false), do: {:error, "Wrong move"}
    
    defp validate_move(:ok, :ok), do: :ok
    defp validate_move(:ok, reply), do: reply
    defp validate_move(reply, :ok), do: reply
    defp validate_move(reply, _), do: reply

    defp update_ships(player, reply = {:error, _}), do: {player, reply}
    defp update_ships(player_data, {:ok, ships}) do
        new_player_data = %{player_data | ships: ships}
        {new_player_data, :ok}
    end

    defp set_in_game(players, uuid) do
        Enum.reduce(players, :ok,
            fn({_, player}, _) ->
                Battleships.Player.set_in_game(player, uuid)
            end)
    end

    defp initialize_state(players) do
        IO.inspect(players, label: "init state players in game")
        List.foldl(players, Map.new(), 
            fn(player_name, acc) ->
                Map.put_new(acc, player_name, %Battleships.GamePlayerData{})
            end)
    end
    
end