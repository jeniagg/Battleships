defmodule Battleships.Server do

    @moduledoc """
    The module represents the main server of the application.
    """

    use GenServer

    defstruct [players: [], rooms: []]

    @type server(players, rooms) :: %Battleships.Server{players: players, rooms: rooms}
    @type server :: %Battleships.Server{players: List, rooms: List}
  
    def start() do
        GenServer.start(__MODULE__, [], [name: __MODULE__])
    end

    def start_link() do
        GenServer.start_link(__MODULE__, [], [name: __MODULE__]) 
    end

    def init([]) do
        :pg2.create(:servers)
        :pg2.join(:servers, self())
        {:ok, %Battleships.Server{} }
    end


    ######################### API FUNCTIONS ########################
    
    @doc ~S"""
    User can login to the system through this API function

    The name of the player should be unique.

    Examples

        iex> Battleships.Server.login("pesho_test")
        {:ok, "pesho_test"}
        
        iex> Battleships.Server.login("pesho_test")
        {:error, "Username taken"}
    """
    @spec login(String) :: {:ok, String} | {:error, String}
    def login(player_name) do
        GenServer.call(__MODULE__, {:login, player_name})
    end

    @doc ~S"""
    A player can leave the system through this function

    The player should be present.

    Examples

        iex> Battleships.Server.logout("pesho")
        :ok
    """
    @spec logout(String) :: :ok
    def logout(player_name) do
        GenServer.cast(__MODULE__, {:logout, player_name})
    end
    
    @doc ~S"""
    Get a list with all available rooms on the server.

    Examples

        iex> Battleships.Server.get_rooms()
        {:ok, []}
    """
    @spec get_rooms() :: {:ok, List}
    def get_rooms() do
        GenServer.call(__MODULE__, :get_rooms)
    end

    @doc ~S"""
    A player can create a room through this function.

    The name of the room should be unique and the player should be logged in.
    
    Arguments
        player_name - the name of the player to create a room
        room_name - the name of the room the player wants to create

    Examples

        iex> Battleships.Server.create_room("room", "pesho_test")
        {:ok, "room"}

        iex> Battleships.Server.create_room("room", "pesho_test")
        {:error, "Room with this name already exists."}
 
        iex> Battleships.Server.create_room("b", "room3")
        {:error, "No such player"}
    """
    @spec create_room(String, String) :: {:ok, String} | {:error, String}
    def create_room(room_name, player_name) do
        GenServer.call(__MODULE__, {:create_room, room_name, player_name})
    end

     @doc ~S"""
    A player can enter in a room through this function.

    The room player and the room should be present.
    
    Arguments
        player_name - the name of the player to enter in a room
        room_name - the name of the room the player wants to enter in

    Examples

        iex> Battleships.Server.enter_room("test_room", "gosho")
        {:error, "Room with this name doesn't exists"}

        iex> Battleships.Server.enter_room("room", "g")
        :error
 
        iex> Battleships.Server.enter_room("room3", "gosho")
        {:ok, "643fa07a-e7b4-42ac-a5ed-c3b51f465959"}
    """
    @spec enter_room(String, String) :: {:ok, UUID} | {:error, String} | :error
    def enter_room(room_name, player_name) do
        GenServer.call(__MODULE__, {:enter_room, room_name, player_name}, :infinity)
    end

    @doc ~S"""
    A player can leave a room through this function.

    The player should be present.

    Arguments
        player_name - the name of the player to leave the room
        room_name - the name of the room the player wants to leave

    Examples

        iex6> Battleships.Server.leave_room("room3", "pesho")
        :ok
    """
    @spec leave_room(String, String) :: :ok
    def leave_room(room_name, player_name) do
        GenServer.cast(__MODULE__, {:leave_room, room_name, player_name})
    end

    @doc ~S"""
    State of the present server

    Examples

        iex> Battleships.Server.inspect_state()
        %Battleships.Server{players: ["pesho_test"], rooms: []}
    """
    @spec inspect_state() :: server
    def inspect_state() do
        GenServer.call(__MODULE__, :inspect_state)
    end

    @doc ~S"""
    Gets all players on the specified server.
    """
    @spec get_local_players(Battleships.Server) :: List
    def get_local_players(server) do
        GenServer.call(server, :get_local_players)
    end

    @doc ~S"""
    Get all rooms on the specified server.
    """
    @spec get_local_rooms(Battleships.Server) :: List
    def get_local_rooms(server) do
        GenServer.call(server, :get_local_rooms)
    end

    ######################### HANDLE CALL ########################

    def handle_call(:inspect_state, _, state) do
        {:reply, state, state}
    end
 
    def handle_call(:get_local_players, _, state) do
        {:reply, state.players, state}
    end
    
    def handle_call(:get_local_rooms, _, state) do
        {:reply, state.rooms, state}
    end
    
    def handle_call({:login, player_name}, _, state) do
        IO.inspect(Enum.member?(state.players, player_name), label: "is logged")
        case is_logged?(state.players, player_name) do
            true -> {:reply, {:error, "Username taken"}, state}
            false -> 
                Battleships.PlayerSup.create_player(player_name)
                new_state = %Battleships.Server{players: [player_name | state.players], rooms: state.rooms}
                {:reply, {:ok, player_name}, new_state}
        end
    end   
    
    def handle_call(:get_rooms, _, state) do
       {:reply, {:ok, state.rooms}, state}
    end

    def handle_call({:create_room, room_name, player_name}, _, state) do
        case is_room_created?(state.rooms, room_name) do
            false ->
                is_logged_player = is_logged?(state.players, player_name)
                {reply, state} = new_room(is_logged_player, state, room_name, player_name)
                {:reply, reply, state}
            true -> {:reply, {:error, "Room with this name already exists."}, state}
        end
    end

    def handle_call({:enter_room, room_name, player_name}, _, state) do
        case is_room_created?(state.rooms, room_name) do
            false -> {:reply, {:error, "Room with this name doesn't exists"}, state}
            true ->
                is_logged = is_logged?(state.players, player_name)
                {game_reply, new_state} = set_player_in_room(is_logged, player_name, room_name, state)
                {:reply, game_reply, new_state}
        end
    end

   ########################## HANDLE CAST  ##########################


    def handle_cast({:logout, player_name}, state) do
        case is_logged?(state.players, player_name) do
            false -> {:noreply, state}
            true -> 
                Battleships.Player.stop(player_name)
                new_players = List.delete(state.players, player_name)
                new_state = %Battleships.Server{players: new_players, rooms: state.rooms}
                {:noreply, new_state}
        end
    end

    def handle_cast({:leave_room, room_name, player_name}, state) do
        case is_room_created?(state.rooms, room_name) do
            false -> {:noreply, state}
            true -> 
                new_state = %{state | rooms: List.delete(state.rooms, room_name)}
                Battleships.Rooms.leave_room(room_name, player_name)
                {:noreply, new_state}
        end 
    end


    ########################## PRIVATE FUNCTIONS   ##########################


    defp new_room(false, state, _, _), do: {{:error, "No such player"}, state}
    defp new_room(true, state, room_name, player_name)  do
        Battleships.RoomSup.create_room(room_name, player_name)
        new_state = %Battleships.Server{players: state.players, rooms: [ room_name | state.rooms ]}
        {{:ok, room_name}, new_state}
    end

    defp set_player_in_room(false,_, _, _), do: {:error, "No such player"}
    defp set_player_in_room(true, player_name, room_name, state) do
        game = Battleships.Rooms.enter_room(room_name, player_name)
        new_state = case game do
            nil -> state
            _ -> new_state = %{state | rooms: List.delete(state.rooms, room_name)}
                 Battleships.Rooms.stop(room_name)
                 new_state
        end
        {game, new_state}
    end

    defp is_logged?(players, player_name) do
        all_players = get_all_players(self(), players)
        Enum.member?(all_players, player_name)
    end

    defp is_room_created?(rooms, room_name) do
        all_rooms = get_all_rooms(self(), rooms)
        Enum.member?(all_rooms, room_name)
    end

    defp get_all_players(current_server, current_node_players) do
        all_servers = :pg2.get_members(:servers)
        List.foldl(all_servers, [],
            fn
                (server, acc) when current_server == server -> Enum.concat(current_node_players, acc)
                (server, acc) ->
                    players = Battleships.Server.get_local_players(server)
                    Enum.concat(players, acc)
            end
        )
    end

    defp get_all_rooms(current_server, current_node_romes) do
        all_servers = :pg2.get_members(:servers)
        List.foldl(all_servers, [],
            fn
                (server, acc) when current_server == server -> Enum.concat(current_node_romes, acc)
                (server, acc) ->
                    rooms = Battleships.Server.get_local_rooms(server)
                    Enum.concat(rooms, acc)
            end
        )
    end

end



