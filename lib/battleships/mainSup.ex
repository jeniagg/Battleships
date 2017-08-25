defmodule Battleships.Supervisor do
    
    @moduledoc """
    The module represents the main supervisor of the game.
    If this supervisor dies, the whole game dies.
    """

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