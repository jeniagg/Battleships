defmodule Battleships.Rooms do
    @moduledoc """
    The module represents the rooms server.
    It is responsible for activites such as leaving a room or entering a room.
    """

    use GenServer

    defstruct [:name, :pid, counter:  0, players: Map.new()]

    @doc """
    Start the room
    """
    def start(name, player_data) do
        GenServer.start(__MODULE__, [name, player_data], [])
    end

    def start_link(room_name, player_data) do
        GenServer.start_link(__MODULE__, [room_name, player_data], []) 
    end

    def init([room_name, {player_name, player}]) do
        {:ok, %Battleships.Rooms{name: room_name, pid: self(), counter: 1, players: %{player_name => player} }}
    end

    def inspect_state(room_name) do
        GenServer.call(room_name, :inspect_state)
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
    # room -> room_pid
    def enter_room(room, player_data) do
        GenServer.call(room, {:enter_room, player_data})
    end


    def leave_room(room, player_name) do
        GenServer.cast(room, {:leave_room, player_name}) 
    end


    def handle_call(:inspect_state, _, state) do
        {:reply, state, state}
    end

    def handle_call({:enter_room, {player_name, player}}, _, state) do
        new_state = %{ state | players: %{state.players | player_name => player}, counter: state.counter + 1}
        pid = start_game(new_state.counter, new_state.players)
        {:reply, {:ok, pid}, new_state}
    end

    def handle_cast({:leave_room, player_name}, state) do
        case Map.fetch(state.players, player_name) do
            {:ok, _} -> 
                new_state = %{ state | players: Map.delete(state.players, player_name), counter: state.counter - 1}
                check_counter(new_state.pid, new_state.counter)
                {:noreply, new_state}
            :error -> {:noreply, state}
        end
    end

    defp start_game(2, players) do
        Battleships.GameSup.create_game(players)
    end

    defp start_game(counter, players) do
        
    end


    defp check_counter(pid, 0) do
        GenServer.stop(pid, :normal)
    end

    defp check_counter(pid, counter) when counter > 0 do
        counter
    end
    
end