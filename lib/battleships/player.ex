defmodule Battleships.Player do

    @moduledoc """
    The module represents the player server.
    It is responsible for player initiatives.
    """

    use GenServer

    defstruct [:name, :pid, game: nil, in_room: false]
  
      
    def start([player_name, state]) do
        GenServer.start(__MODULE__, [player_name, state], name: {:global, player_name})
    end

    def start(player_name) do
        GenServer.start(__MODULE__, [player_name], name: {:global, player_name})
    end

    def start_link([player_name, state]) do
        GenServer.start_link(__MODULE__, [player_name, state], name: {:global, player_name}) 
    end

    
    def start_link(player_name) do
        GenServer.start_link(__MODULE__, [player_name], name: {:global, player_name}) 
    end

    def init([player_name]) do
        IO.inspect(player_name, label: "Starting player: ")
        {:ok, %Battleships.Player{name: player_name, pid: self()}}
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
    
    @doc ~S"""
    A player can create a room through this function.

    The name of the room should be unique and the player should be logged in.
    
    Arguments
        player - the name of the player to create a room
        room_name - the name of the room the player wants to create

    Examples

        iex> Battleships.Player.create_room("az", "room1")
        {:error, "Room with this name already exists"}

        iex> Battleships.Player.create_room("pesho_test", "room7")
        {:ok, "room"}


    """
    # @spec create_room(String|{node, String}, String) :: {:ok, pid} | {:error, String}
    def create_room(player_name, room_name) do
        GenServer.call({:global, player_name}, {:create_room, room_name})
    end

    @doc ~S"""
    Player can enter a room, which is already present.

    The player shoul be logged in.
    
    Arguments
        player - the name of the player to enter a room
        room_name - the name of the room the player wants to enter

    Examples

        iex> Battleships.Player.enter_room("pesho_test", "room1")
        # {:ok, "93a3ee09-e24a-4a46-a17d-8c9520b108c7"}
 
        iex> Battleships.Player.enter_room("gosho", "room2")
        {:error, "Room with this name doesn't exists"}
    

    """
    def enter_room(player_name, room_name) do   
        GenServer.call({:global, player_name}, {:enter_room, room_name}, :infinity)  
    end

    @doc ~S"""
    A player can leave a room through this function.

    The player should be present.

    Examples

        iex> Battleships.Player.leave_room("pesho", "room")
        :ok
    """
    def leave_room(player_name, room_name) do
        GenServer.cast({:global, player_name}, {:leave_room, room_name})
    end

    @doc ~S"""
    Logout from the system.
    
    If the player is in room and/or game, they will be destroyed.

    Arguments
        player_name -> the name of the player

    Examples

        iex> Battleships.Player.logout("pesho")
        :ok
    """
    def logout(player_name) do
        GenServer.cast({:global, player_name}, :logout)
    end

    @doc ~S"""
    State of the present player

    Arguments: 
        player_name -> the name of the player

    Examples

        iex> Battleships.Player.inspect_state("pesho")
        %Battleships.Player{game: nil, in_room: false, name: "pesho", pid: :global.whereis_name("pesho")}
    """
    def inspect_state(player_name) do
        GenServer.call({:global, player_name}, :inspect_state)
    end

    @doc ~S"""
    Put player in a game. The player and game should be present.

    Arguments
        player_name -> the name of the player to be put in the game
        game_name -> the name of the game to put the player in

    Examples

        iex> Battleships.Player.set_in_game("pesho", "room")
        :ok
    """
    # @spec set_in_game(String, String)::
    def set_in_game(player_name, game_name) do
        GenServer.cast({:global, player_name}, {:set_in_game, game_name})
    end

    @doc ~S"""
    Create a board for the game for the present player. 

    Arguments:
        player_name -> the name of the player
        ships -> the ships of the player

    Examples
        iex> Battleships.Player.create_board("a",[{:vertical, {6,2}, 2}, {:horizontal, {1,3}, 3}, {:horizontal, {7,8}, 2}, {:vertical, {3,7}, 5}, {:vertical, {5,6}, 2}])
        :ok

        iex>  Battleships.Player.create_board("a",[{:vertical, {6,2}, 2}, {:horizontal, {1,3}, 3}, {:horizontal, {7,8}, 2}, {:vertical, {3,7}, 5}, {:vertical, {1,2}, 2}])
        {:error, "This player already created his board!"}

        iex> Battleships.Player.create_board("a",[{:vertical, {6,11}, 1}, {:horizontal, {1,3}, 2}])
        {:error, "The board can't be created! There are wrong coordinates!"}

        iex> Battleships.Player.create_board("a",[{:vertical, {6,2}, 1}, {:horizontal, {1,3}, 2}])
        {:error, "Wrong number of ships! They must be 5!"}

        iex>  Battleships.Player.create_board("pesho",[{:vertical, {6,2}, 2}, {:horizontal, {1,3}, 3}, {:horizontal, {7,8}, 2}, {:vertical, {3,7}, 5}, {:vertical, {7,2}, 2}])
        {:error, "Different ships can't have same coordinates!"}
    """
    @spec create_board(String, List) :: {:ok, pid} | {:error, String}
    def create_board(player_name, ships) do
        GenServer.call({:global, player_name}, {:create_board, ships})
    end

    @doc ~S"""
    Make move in the game.

    Arguments
        player_name -> the name of the player to make the move
        move -> the coordinates which player what to try {x,y}
 
    Examples

        iex> Battleships.Player.make_move("pesho", {1,2})
        {:error, "It's not your turn."}

        iex> Battleships.Player.make_move("gosho", {1,2})
        :no_hit

        iex> Battleships.Player.make_move("pesho", {1,2})
        :hit
    """
    def make_move(player_name, move) do
        GenServer.call({:global, player_name}, {:make_move, move})
    end

    @doc ~S"""
    Announce that the game is over and sent message to the two players

    Arguments
        player_name -> the name of the player who is present
        winner_name -> the name of the player who won the game
 
    Examples

        iex> Battleships.Player.match_end("pesho", {:winner, "pesho"})
        :ok
    """
    def match_end(player_name, {:winner, winner_name}) do
        GenServer.cast({:global, player_name}, {:match_end, winner_name})
    end

    @doc ~S"""
    Kill the player process normally

    Arguments
        player_name -> the name of the player whose process is to be stopped
 
    Examples
        iex> Battleships.Player.stop("gosho")
        :ok
    """
    # @spec stop(String):: term()
    def stop(player_name) do
      GenServer.call({:global, player_name}, :stop)
    end


    #################### HANDLE CALL ####################


    def handle_call(:inspect_state, _, state) do
        {:reply, state, state}
    end
    
    def handle_call({:enter_room, room_name}, _, state) do
        reply = case state.in_room do
            true -> {:error, "The player is already in a room."}
            false -> Battleships.Server.enter_room(room_name, state.name) 
        end 
        {:reply, reply, state}
    end

    def handle_call({:create_room, room_name}, _, state) do
       reply = Battleships.Server.create_room(room_name, state.name) 
       new_state = case reply do
            {:ok, _} -> %{state | in_room: true}
            {:error, _} -> state
       end
       {:reply, reply, new_state}  
    end    

    def handle_call({:create_board, ships}, _, state) do
        reply = Battleships.Games.create_board(state.game, ships, state.name)
        {:reply, reply, state}
    end

    def handle_call({:make_move, move}, _, state) do
        reply = Battleships.Games.make_move(state.game, state.name, move)
        {:reply, reply, state}
    end

    def handle_call(:stop, _, state) do
        {:stop, :normal, :ok, state}
    end
    
    ################## HANDLE CAST ###################

    def handle_cast({:leave_room, room_name}, state) do
        case state.game != nil do
           true -> Battleships.Games.stop(state.game)
           false -> :ok
        end
        new_state = %{state | in_room: false, game: nil}
        Battleships.Server.leave_room(room_name, state.name)
        {:noreply, new_state}
    end
    
    def handle_cast(:logout, state) do
        Battleships.Server.logout(state.name)
        {:noreply, state}
    end

    def handle_cast({:set_in_game, new_game}, state) do
        new_state = %{state | game: new_game, in_room: false}
        {:noreply, new_state}
    end

    def handle_cast({:match_end, winner_name}, state) do
        case winner_name == state.name do
            true -> IO.inspect(winner_name, label: "The winner is: ")
            false -> IO.puts("GAME OVER")
        end
        new_state = %{state | game: nil}
        {:noreply, new_state}
    end

end