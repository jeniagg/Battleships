defmodule Battleships.GamePlayerData do

    @moduledoc """
    The module is responsible for generating the game board.
    """

    defstruct [ships: [], player: nil]


    @doc ~S"""
    Generates the ships, respectively a board of a player

    Arguments
        ships -> the ships that need to be created
 
    Examples

        iex> Battleships.GamePlayerData.generate_ships([{:vertical, {6,2}, 2}, {:horizontal, {1,3}, 3}, {:horizontal, {7,8}, 2}, {:vertical, {3,7}, 5}, {:vertical, {5,6}, 2}])
        {:ok,  [[{6, 2}, {7, 2}], [{1, 3}, {1, 4}, {1, 5}], [{7, 8}, {7, 9}], [{3, 7}, {4, 7}, {5, 7}, {6, 7}, {7, 7}], [{5, 6}, {6, 6}]]}
        
        iex> Battleships.GamePlayerData.generate_ships([{:vertical, {6,2}, 2}, {:horizontal, {1,3}, 3}])
        {:error, "Wrong number of ships! They must be 5!"}

        iex> Battleships.GamePlayerData.generate_ships([{:vertical, {-6,2}, 2}, {:horizontal, {1,3}, 3}, {:horizontal, {7,8}, 2}, {:vertical, {3,7}, 5}, {:vertical, {5,6}, 2}])
        {:error, "The board can't be created! There are wrong coordinates!"}
    """
    def generate_ships(ships) do
        board = Enum.map(ships,
                    fn({orientation, {x,y}, size}) -> 
                    create_ship(orientation, {x,y}, size)  
                end)
        valid = is_valid_board(board)
        correct_number_ships = is_correct_number_of_ships(length(board))
        generate_board(valid, correct_number_ships, board)
    end

    def get_ships(player), do: player.ships

    @doc ~S"""
    Apply the specified move.

    Checks for hit/no_hit and updates the ships if needed.
    """
    def apply_move(move, ships) do
        hit_index = get_hit_index(move, ships)
        hit_ships(hit_index, ships, move)
    end

    @doc ~S"""
    Validate correctness of coordinates.
    """
    def is_valid({:x, x}) do
        x > 0 and x <= board_size()
    end

    def is_valid({:y, y}) do
        y > 0 and y <= board_size()
    end

    def is_valid({x, y}) do
        is_valid({:x, x}) and is_valid({:y, y})
    end

    ########################### PRIVATE FUNCTIONS ###########################

    defp get_hit_index(move, ships) do
        Enum.find_index(ships,
            fn(ship) ->
                Enum.member?(ship, move)
            end
        )
    end

    defp is_correct_number_of_ships(5), do: true
    defp is_correct_number_of_ships(_), do: false

    defp hit_ships(nil, ships, _), do: {:no_hit, ships}
    defp hit_ships(index, ships, move) do
        ship = Enum.at(ships, index)
        new_ship = List.delete(ship, move)
        {:hit, update_ships(new_ship, ships, index)}

    end

    defp update_ships([], ships, index), do: List.delete_at(ships, index)
    defp update_ships(new_ship, ships, index), do: List.update_at(ships, index, fn(_) -> new_ship end)

    defp is_valid_board(board) do
        List.foldl(board, true, 
            fn
                ({:error, _}, _) -> false
                (_, acc) -> acc
            end
        )
    end

    defp generate_board(true, true, board) do
        {:ok, board}
    end

    defp generate_board(false, _, _) do
        {:error, "The board can't be created! There are wrong coordinates!"}
    end

    defp generate_board(_, false, _), do: {:error, "Wrong number of ships! They must be 5!"}

    # TODO if there is already a ship on this coordinates, when try to create a new one -> error
    defp create_ship(orientation, {x,y}, size) do
       create_ship(orientation, {x,y}, size, is_valid({x, y}) and size > 0)
    end

    defp create_ship(:vertical, {x,y}, size, true) do
        new_x = x + size - 1
        case is_valid({:x, new_x}) do
            true -> for n <- x..new_x, do: {n, y}
            false -> {:error, "The ship can't be created"}
        end

    end

    defp create_ship(:horizontal, {x,y}, size, true) do
        new_y = y + size - 1
        case is_valid({:y, new_y}) do
            true -> for n <- y..new_y, do: {x, n} 
            false -> {:error, "The ship can't be created"}
        end
    end

    defp create_ship(_, {_, _}, _size, false) do
        {:error, "The ship can't be created"}
    end

    defp board_size() do
        10
    end 

end