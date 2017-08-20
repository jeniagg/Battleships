defmodule Battleships.Supervisor do
    
    use Supervisor

    def start_link() do
        Supervisor.start_link(__MODULE__, [], [name: __MODULE__])
    end

    def init([]) do
        children = [
            worker(Battleships.Server, []),
            supervisor(Battleships.GameSup, []),
            supervisor(Battleships.PlayerSup, []),
            supervisor(Battleships.RoomSup, [])
        ]
        opts = [strategy: :one_for_one]
        supervise(children, opts)
    end
end