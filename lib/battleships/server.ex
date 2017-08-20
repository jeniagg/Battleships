defmodule Battleships.Server do
    use GenServer

    # TODO: terminate

    defstruct [players: Map.new(), rooms: Map.new()]

    def start() do
        GenServer.start(__MODULE__, [], [name: __MODULE__])
    end

    def start_link() do
        GenServer.start_link(__MODULE__, [], [name: __MODULE__]) 
    end

    def init([]) do
        {:ok, %Battleships.Server{} }
    end
    
    # interface which the player use to enters the system
    def login(name) do
        GenServer.call(__MODULE__, {:login, name})
    end

    # interface which the player use to leave the system
    def logout(name) do
        GenServer.cast(__MODULE__, {:logout, name})
    end

    # interface which the player use to get list of all active rooms
    def get_rooms() do
        GenServer.call(__MODULE__, :get_rooms)
    end

    #interface which the player use to create a room
    def create_room(name, player_name) do
        GenServer.call(__MODULE__, {:create_room, name, player_name})
    end

    #interface which the player use to enter in a room
    def enter_room(room_name, player_name) do
        GenServer.call(__MODULE__, {:enter_room, room_name, player_name})
    end

    # interface to delete a room
    # def remove_room(name) do
    #     GenServer.cast(__MODULE__, {:remove_room, name})
    # end

    # interface to leave a room
    def leave_room(room_name, player_name) do
        GenServer.cast(__MODULE__, {:leave_room, room_name, player_name})
    end

    def inspect_state() do
        GenServer.call(__MODULE__, :inspect_state)
    end

    # def set_in_game(players, game) do
    #     GenServer.cast(__MODULE__, {:set_in_game, players, game})
    # end

    ######################### Private functions ########################

    def handle_call(:inspect_state, _, state) do
        {:reply, state, state}
    end
    

    # the server handle the login interface
    def handle_call({:login, name}, _, state) do
        case Map.fetch(state.players, name) do
            {:ok, _} -> 
                {:reply, {:error, "Username taken"}, state}
            :error -> 
                player_pid = Battleships.PlayerSup.create_player(name)
                new_state = %Battleships.Server{players: Map.put(state.players, name, player_pid), rooms: state.rooms}
                {:reply, {:ok, player_pid}, new_state}
        end
    end   
    

    
    # the server handle the get_rooms interface
    def handle_call(:get_rooms, _, state) do
       {:reply, {:ok, Map.keys(state.rooms)}, state}
    end

    # the server handle the create_room interface
    # TODO check if the name of the player exists
    def handle_call({:create_room, name, player_name}, _, state) do
        case Map.fetch(state.rooms, name) do
            {:ok, _} -> {:reply, {:error, "Room with this name already exists."}, state}
            :error ->
                player = Map.fetch(state.players, player_name)
                {reply, state} = new_room(player, state, name, player_name)
                # room_pid = Battleships.RoomSup.create_room(name, player_name)
                # new_state = %Battleships.Server{players: state.players, rooms: Map.put(state.rooms, name, room_pid)}
                {:reply, reply, state}
        end
    end

    # leave room
    # def handle_call({:leave_room, room_name, player_name}, _, state) do
    #     # check if the room exists
    #     case Map.fetch(state.rooms, room_name) do
    #         {:ok, room} -> 
    #             Battleships.Rooms.leave_room(room, player_name)
    #             {:reply, :ok, state}
    #         :error -> {:reply, {:error, "There is no such room"}, state}
    #     end 
    # end





    # the server handle the enter_room interface
    # TODO after the game is on, send msg to the both players
    def handle_call({:enter_room, room_name, player_name}, _, state) do
        case Map.fetch(state.rooms, room_name) do
            {:ok, room} ->
                player = Map.fetch(state.players, player_name)
                {game_reply, new_state} = set_player_in_room(player, player_name, room, room_name, state)
                {:reply, game_reply, new_state}
            :error -> {:reply, {:error, "Room with this name doesn't exists"}, state}
        end
    end

    # # delete room if there is noone there (wrong name for example)
    # def handle_cast({:remove_room, name}, state) do
    #     case Map.fetch(state.rooms, name) do
    #         {:ok, room} ->
    #             :erlang.exit(room, :normal)
    #             new_state = %{ state | rooms: Map.delete(state.rooms, name)}
    #             {:noreply, new_state}
    #         :error -> {:noreply, state}
    #     end
    # end

        # the server handle the logout interface
    def handle_cast({:logout, name}, state) do
        case Map.fetch(state.players, name) do
            {:ok, player} -> 
               # PlayerSup.delete_player(name)
                GenServer.stop(player, :normal)
                new_players = Map.delete(state.players, name)
                new_state = %Battleships.Server{players: new_players, rooms: state.rooms}
                {:noreply, new_state}
            :error -> {:noreply, state}
        end
    end

    def handle_cast({:leave_room, room_name, player_name}, state) do
        # check if the room exists
        case Map.fetch(state.rooms, room_name) do
            {:ok, room} -> 
                Battleships.Rooms.leave_room(room, player_name)
                {:noreply, state}
            :error -> {:noreply, state}
        end 
    end
    
    # def handle_cast({:set_in_game, players, game}, state) do
    #     List.foldl(players, :ok,
    #         fn(player_name, _) ->
    #              {:ok, player} = Map.fetch(state.players, player_name)
    #              Battleships.Player.set_in_game(player, game)
    #         end)
    #     {:noreply, state}
    # end
    

    # defp delete_room(room_name) do
    #     room = Rooms.get_room(room_name)
    #     case room.counter do
    #         0 -> RoomSup.remove_room(room_name)
    #             #

    #         _ -> {:reply, {:error, "Room can not be removed, there is a player in it."}}
    #     end
            
    # end
    
    defp new_room(:error, state, _, _) do
        {{:error, "No such player"}, state}
    end

    defp new_room({:ok, player}, state, room_name, player_name)  do
        room_pid = Battleships.RoomSup.create_room(room_name, {player_name, player})
        new_state = %Battleships.Server{players: state.players, rooms: Map.put(state.rooms, room_name, room_pid)}
        {{:ok, room_pid}, new_state}
    end


    defp set_player_in_room({:ok, player}, player_name, room, room_name, state) do
        game = Battleships.Rooms.enter_room(room, {player_name, player})
        new_state = %{state | rooms: Map.delete(state.rooms, room_name)}
        GenServer.stop(room, :normal)
        {game, new_state}
    end

    defp set_player_in_room(:error,_, _, _, _) do
        {:error, "No such player"}
    end

end



