defmodule Battleships.RoomSup do
    use Supervisor

    @moduledoc """
    The module represents the Supervisor of the Room processes.
    The used strategy is simple_one_for_one and the restart is transient.
    """
    
    def start_link() do
        Supervisor.start_link(__MODULE__, [], [name: __MODULE__])
    end

    def init([]) do
        children = [worker(Battleships.Rooms, [], restart: :transient)]
        opts = [strategy: :simple_one_for_one]
        supervise(children, opts)
    end
    
    def create_room(room_name, player_name) do
        {:ok, pid} = Supervisor.start_child(__MODULE__, [room_name, player_name])
        pid
    end
end