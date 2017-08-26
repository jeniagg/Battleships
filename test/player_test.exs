defmodule Battleships.PlayerTest do
    use ExUnit.Case, async: false
    doctest Battleships.Player

    setup do
        Battleships.Server.start_link()
        {:ok, pesho_pid} = Battleships.Player.start_link("pesho")
        {:ok, _} = Battleships.Player.start_link("gosho")
        {:ok, test_player} = Battleships.Player.start_link("test_player")
        {:ok, room1} = Battleships.Rooms.start_link("room1", "gosho")
        {:ok, game} = Battleships.Games.start_link(["pesho", "gosho"], "93a3ee09-e24a-4a46-a17d-8c9520b108c7")
        {:ok, pesho: :global.whereis_name("pesho")}
        {:ok, game: "93a3ee09-e24a-4a46-a17d-8c9520b108c7"}
        {:ok, test_player: :global.whereis_name("test_player")}
        {:ok, test_player: test_player}
        {:ok, room1: :global.whereis_name("room1")}
        {:ok, room1: room1}

        :ok
    end

end
