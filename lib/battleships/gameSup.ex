defmodule Battleships.GameSup do
    
    use Supervisor

    def start_link() do
        Supervisor.start_link(__MODULE__, [], [name: __MODULE__])
    end

    def init([]) do
        children = [worker(Battleships.Games, [])]
        opts = [strategy: :simple_one_for_one]
        supervise(children, opts)
    end

    def create_game(players) do
        {:ok, pid} = Supervisor.start_child(__MODULE__, [players])
        pid
    end


end