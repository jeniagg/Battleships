defmodule Battleships.Rooms do
   
    @moduledoc """
    The module represents the rooms server.
    It is responsible for activites such as leaving a room or entering a room.
    """

    use GenServer

    defstruct [:name, :pid, counter:  0, players: [] ]

    def start(room_name, player_name) do
        GenServer.start(__MODULE__, [room_name, player_name], name: {:global, room_name})
    end

    def start_link(room_name, player_name) do
        GenServer.start_link(__MODULE__, [room_name, player_name], name: {:global, room_name}) 
    end

    def init([room_name, player_name]) do
        {:ok, %Battleships.Rooms{name: room_name, pid: self(), counter: 1, players: [player_name] }}
    end

    def child_spec(args) do
        %{
            id: Battleships.Rooms,
            start: {Battleships.Rooms, :start_link, [args]},
            restart: :transient,
            shutdown: 5000,
            type: :worker       
        }
    end

    ########################### API FUNCTIONS ###########################

    @doc ~S"""
    State of a present room

    Arguments: 
        room_name -> the name of the room

    Examples

        iex> Battleships.Rooms.inspect_state("room3")
        %Battleships.Rooms{counter: 1, name: "room3", pid: :global.whereis_name("room3"), players: ["pesho"]}
    """
    def inspect_state(room_name) do
        GenServer.call({:global, room_name}, :inspect_state)
    end

    @doc ~S"""
    Kill the room process normally

    Arguments
        room_name -> the name of the room which process is to be stopped
 
    Examples
        iex> Battleships.Rooms.stop("room3")
        :ok
    """
    def stop(room_name) do
      GenServer.call({:global, room_name}, :stop)
    end

    @doc ~S"""
    A player can enter a room through this function.

    The player and the room should be present.
    If the room or the player is nor present, it returns just :ok.
    If they are present, thi uuid of the game is returned.

    Examples

        iex> Battleships.Rooms.enter_room("room", "a")
        {:ok, "373fe0fa-5dff-4dfa-84f5-e520adca11c5"}

        iex> iex(mix@Jenia-PC)8> Battleships.Rooms.enter_room("room", "ds")
        {:ok, :ok}
    """
    def enter_room(room_name, player_name) do
        GenServer.call({:global, room_name}, {:enter_room, player_name}, :infinity)
    end

    @doc ~S"""
    A player can leave a room through this function.

    The player and the room should be present.

    Examples

        iex> Battleships.Rooms.leave_room("room3", "pesho")
        :ok
    """
    def leave_room(room_name, player_name) do
        GenServer.cast({:global, room_name}, {:leave_room, player_name}) 
    end


    ########################### HANDLE CALL ###########################

    def handle_call(:stop, _, state) do
        {:stop, :normal, :ok, state}
    end

    def handle_call(:inspect_state, _, state) do
        {:reply, state, state}
    end

    def handle_call({:enter_room, player_name}, _, state) do
        new_state = %{ state | players: [ player_name | state.players], counter: state.counter + 1}
        game = start_game(new_state.counter, new_state.players, new_state)
        {:reply, {:ok, game}, new_state}
    end


    ########################### HANDLE CAST ###########################

    def handle_cast({:leave_room, player_name}, state) do
        case Enum.member?(state.players, player_name) do
            false -> {:noreply, state}
            true -> 
                new_state = %{ state | players: List.delete(state.players, player_name), counter: state.counter - 1}
                check_counter(new_state.pid, new_state.counter)
                {:noreply, new_state}
        end
    end

    ########################### PRIVATE FUNCTIONS ###########################

    defp start_game(2, players, new_state) do
        players_on_the_same_node(players, new_state.name)
        game = Battleships.GameSup.create_game(players)
        [second_player, first_player] = players
    
        List.foldl(players, :ok, 
            fn(player_name, acc) ->
                 Battleships.Player.set_in_game(player_name, game)
            end)
        game
    end

    defp start_game(_, _players, _, _), do: :ok
    
    defp players_on_the_same_node(players, state) do
        IO.inspect(players, label: "node players")
        [second_player, first_player] = players
        node_second = node(:global.whereis_name(second_player))
        node_first = node(:global.whereis_name(first_player))
        case node_second == node_first do
            true -> :ok
            false ->
                :global.unregister_name(second_player)
                Battleships.PlayerSup.create_player(second_player, node_first)
                IO.inspect([node(:global.whereis_name(second_player)) , node(:global.whereis_name(first_player))], label: "NODES " )
        end
    end

    defp check_counter(pid, 0), do: GenServer.stop(pid, :normal)
    defp check_counter(_pid, counter) when counter > 0, do: :ok

end