defmodule Battleships.GameSup do
    
    @moduledoc """
    The module represents the Supervisor of the Game processes.
    The used strategy is simple_one_for_one and the restart is transient.
    """

    use Supervisor

    def start_link() do
        Supervisor.start_link(__MODULE__, [], [name: __MODULE__])
    end

    def init([]) do
        children = [worker(Battleships.Games, [], restart: :transient)]
        opts = [strategy: :simple_one_for_one]
        supervise(children, opts)
    end

    def create_game(players) do
        uuid = UUID.uuid4()
        {:ok, pid} = Supervisor.start_child(__MODULE__, [players, uuid])
        uuid
    end


end