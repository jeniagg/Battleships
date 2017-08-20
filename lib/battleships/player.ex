defmodule Battleships.Player do

    @moduledoc """
    The module represents the player server.
    It is responsible for player initiatives.
    """
    
    # TODO terminate

    use GenServer

    defstruct [:name, :pid, game: nil]

    ########### interface #############
    def start(name) do
        GenServer.start(__MODULE__, [name], [])
    end

    def start_link(name) do
        GenServer.start_link(__MODULE__, [name], []) 
    end

    def init([player_name]) do
        {:ok, %Battleships.Player{name: player_name, pid: self()}}
    end

    
    @doc """
    A player can enter in already created room through this function.
    
    Arguments
        player - the name of the player to enter a room
        room_name - the name of the room the player wants to enter
        
    Returning values
        successfull entering: {:ok, pid_of_the_game}
        unsseccssesfull entering: {:error, message}

    Examples

        iex> {:ok, game} = Battleships.Player.enter_room(pesho, "room1")
        {:ok, #PID<0.121.0>}
 
        iex> Battleships.Player.enter_room(gosho, "room")
        {:error, "Room with this name doesn't exists"}
    """
    def enter_room(player, room_name) do
        GenServer.call(player, {:enter_room, room_name})    
    end

    @doc """
    A player can create a room through this function.

    The name of the room should be unique and the player should be logged in.
    
    Arguments
        player - the name of the player to create a room
        room_name - the name of the room the player wants to create
        
    Returning values
        successfull creating: {:ok, pid_of_the_room}
        unsseccssesfull creating: {:error, message}

    Examples

        iex> {:ok, room} = Battleships.Player.create_room(pesho, "room1")
        {:ok, #PID<0.166.0>}
 
        iex> Battleships.Player.create_room(gosho, "room1")
        {:error, "Room with this name already exists."}
    """
    @spec create_room(pid|String|{node, String}, String) :: {:ok, pid} | {:error, String}
    def create_room(player, room_name) do
        GenServer.call(player, {:create_room, room_name})
    end

    # TODO : player left ->  game? room?
    def logout(player) do
        GenServer.cast(player, :logout)
    end

    
    @doc """
    A player can leave a room through this function.

    The player should be present.

    Examples

        iex> Battleships.Player.leave_room(pesho, "room")
        :ok
    """
    def leave_room(player, room_name) do
        GenServer.cast(player, {:leave_room, room_name})
    end

    def inspect_state(player) do
        GenServer.call(player, :inspect_state)
    end

    def create_board(player, ships) do
        GenServer.call(player, {:create_board, ships})
    end

    def set_in_game(player, game) do
        GenServer.cast(player, {:set_in_game, game})
    end

    def make_move(player, move) do
        GenServer.call(player, {:make_move, move})
    end

    def match_end(player, {:winner, winner_name}) do
        GenServer.cast(player, {:match_end, winner_name})
    end

    ########## Handle call ##########

    def handle_call(:inspect_state, _, state) do
        {:reply, state, state}
    end

    def handle_call({:enter_room, room_name}, _, state) do
        reply = Battleships.Server.enter_room(room_name, state.name)  
        {:reply, reply, state}  
    end

    def handle_call({:create_room, room_name}, _, state) do
       reply = Battleships.Server.create_room(room_name, state.name) 
       {:reply, reply, state}  
    end    

    def handle_call({:create_board, ships}, _, state) do
        reply = Battleships.Games.create_board(state.game, ships, state.name)
        {:reply, reply, state}
    end

    def handle_call({:make_move, move}, _, state) do
        Battleships.Games.make_move(state.game, state.name, move)
    end
    
    ######### Handle cast ##########

    def handle_cast({:leave_room, room_name}, state) do
        Battleships.Server.leave_room(room_name, state.name)
        {:noreply, state}
    end
    
    def handle_cast(:logout, state) do
        Battleships.Server.logout(state.name)
        {:noreply, state}
    end

    def handle_cast({:set_in_game, game}, state) do
        new_state = %{state | game: game}
        {:noreply, new_state}
    end

    def handle_cast({:match_end, winner_name}, state) do
        case winner_name == state.name do
            true -> IO.puts("You won the game!")
            false -> IO.puts("You have lost the game!")
        end
        new_state = %{state | game: nil}
        {:reply, new_state}
    end

    def child_spec(args) do
        %{
            id: Battleships.Player,
            start: {Battleships.Player, :start_link, [args]},
            restart: :transient,
            shutdown: 5000,
            type: :worker       
        }
    end

end