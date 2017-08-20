defmodule Battleships.PlayerSup do
    
    use Supervisor

    def start_link() do
        Supervisor.start_link(__MODULE__, [], [name: __MODULE__])
    end

    def init([]) do
        children = [worker(Battleships.Player, [])]
        opts = [strategy: :simple_one_for_one]
        supervise(children, opts)
        #Supervisor.init([Player.child_spec([])], strategy: :simple_one_for_one)
    end
    
    def create_player(name) do
        {:ok, pid} = Supervisor.start_child(__MODULE__, [name])
        pid
    end

    # def delete_player(name) do
    #     Supervisor.terminate_child(__MODULE__, name)
    # #   Supervisor.delete_child(__MODULE__, name)
    # end
    
end