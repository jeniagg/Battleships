defmodule Battleships.GamesTest do
  use ExUnit.Case, async: false
  doctest Battleships.Games

    setup do
        {:ok, _} = Battleships.Player.start_link("gosho")
        {:ok, test_player} = Battleships.Player.start_link("test_player")
        {:ok, room1} = Battleships.Rooms.start_link("room1", "gosho")
        {:ok, game} = Battleships.Games.start_link(["pesho", "gosho"], "4de61b65-a28b-4083-b370-95f7e19fe748")
        {:ok, pesho: :global.whereis_name("pesho")}
        {:ok, game: "4de61b65-a28b-4083-b370-95f7e19fe748"}
        {:ok, test_player: :global.whereis_name("test_player")}
        {:ok, test_player: test_player}
        {:ok, room1: :global.whereis_name("room1")}
        {:ok, room1: room1}
        {:ok, game_pid} = Battleships.Games.start_link(["pesho","gosho"], "4de61b65-a28b-4083-b370-95f7e19fe748")
        {:ok, uuid: "4de61b65-a28b-4083-b370-95f7e19fe748"}
        :ok
    end

end
