defmodule Battleships.PlayerSup do
    
    @moduledoc """
    The module represents the Supervisor of the Player processes.
    The used strategy is simple_one_for_one and the restart is transient.
    """

    use Supervisor

    def start_link() do
        Supervisor.start_link(__MODULE__, [], [name: __MODULE__])
    end

    def init([]) do
        children = [worker(Battleships.Player, [], restart: :transient)]
        opts = [strategy: :simple_one_for_one]
        supervise(children, opts)
    end
    
    def create_player(name) do
        {:ok, pid} = Supervisor.start_child(__MODULE__, [name])
        pid
    end

    def create_player(player_name, node) do
        {:ok, pid} = Supervisor.start_child({__MODULE__, node}, [player_name])
        pid
    end

end