defmodule Battleships.GamePlayerData do
    defstruct [ships: [], player: nil]

    # used for creating the board
    def generate_ships(ships) do
        board = Enum.map(ships,
                    fn({orientation, {x,y}, size}) -> 
                    create_ship(orientation, {x,y}, size)  
                end)
        valid = is_valid_board(board)
        generate_board(valid, board)
    end

    def get_ships(player), do: player.ships

    def apply_move(move, ships) do
        hit_index = get_hit_index(move, ships)
        hit_ships(hit_index, ships, move)
    end

    defp get_hit_index(move, ships) do
        Enum.find_index(ships,
            fn(ship) ->
                Enum.member?(ship, move)
            end
        )
    end

    defp hit_ships(nil, ships, _), do: {:no_hit, ships}
    defp hit_ships(index, ships, move) do
        ship = Enum.at(ships, index)
        new_ship = List.delete(ship, move)
        {:hit, update_ships(new_ship, ships, index)}

    end

    defp update_ships([], ships, index), do: List.delete_at(ships, index)
    defp update_ships(new_ship, ships, index), do: List.update_at(ships, index, new_ship)

    defp is_valid_board(board) do
        List.foldl(board, true, 
            fn
                ({:error, _}, _) -> false
                (_, acc) -> acc
            end
        )
    end

    defp generate_board(true, board) do
        {:ok, board}
    end

    defp generate_board(false, _) do
        {:error, "The board can't be created"}
    end

    # TODO ако има създаден кораб на тези координати вече, да не ми дава да правя нов
    # generate a ship
    defp create_ship(orientation, {x,y}, size) do
       create_ship(orientation, {x,y}, size, is_valid({x, y}) and size > 0)
    end

    defp create_ship(:horizontal, {x,y}, size, true) do
        new_x = x + size
        case is_valid({:x, new_x}) do
            true -> for n <- x..new_x, do: {n, y}
            false -> {:error, "The ship can't be created"}
        end

    end

    defp create_ship(:vertical, {x,y}, size, true) do
        new_y = y + size
        case is_valid({:y, new_y}) do
            true -> for n <- y..new_y, do: {x, n} 
            false -> {:error, "The ship can't be created"}
        end
    end


    defp create_ship(_, {x,y}, size, false) do
        {:error, "The ship can't be created"}
    end


    def is_valid({:x, x}) do
        x > 0 and x <= board_size()
    end

    def is_valid({:y, y}) do
        y > 0 and y <= board_size()
    end

    def is_valid({x, y}) do
        is_valid({:x, x}) and is_valid({:y, y})
    end

    defp board_size() do
        10
    end 

end