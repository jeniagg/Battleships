defmodule Battleships.RoomSup do
    use Supervisor
    
    def start_link() do
        Supervisor.start_link(__MODULE__, [], [name: __MODULE__])
    end

    def init([]) do
        children = [worker(Battleships.Rooms, [])]
        opts = [strategy: :simple_one_for_one]
        supervise(children, opts)
    end
    
    def create_room(room_name, player_data) do
        {:ok, pid} = Supervisor.start_child(__MODULE__, [room_name, player_data])
        pid
    end
end