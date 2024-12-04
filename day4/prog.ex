defmodule WordSearch do
  def find_words(filename) do
    indexed_grid =
      filename
      |> File.read!()
      |> String.split("\n")
      |> Enum.map(&String.trim/1)
      |> Enum.map(&String.graphemes/1)
      |> Enum.with_index()
      |> Enum.flat_map(fn {line, y} ->
        Enum.with_index(line)
        |> Enum.map(fn {char, x} -> {{x, y}, char} end)
      end)
      |> Enum.into(%{})

    # All possible directions to search: right, down-right, down, down-left, left, up-left, up, up-right
    directions = [
      {1, 0},
      {1, 1},
      {0, 1},
      {-1, 1},
      {-1, 0},
      {-1, -1},
      {0, -1},
      {1, -1}
    ]

    # Get grid dimensions
    max_x = indexed_grid |> Map.keys() |> Enum.map(&elem(&1, 0)) |> Enum.max()
    max_y = indexed_grid |> Map.keys() |> Enum.map(&elem(&1, 1)) |> Enum.max()

    # Check every position as a potential starting point
    for x <- 0..max_x,
        y <- 0..max_y,
        direction <- directions,
        valid_word?(indexed_grid, {x, y}, direction, "XMAS") do
      {x, y, direction}
    end
    |> length()
  end

  def find_X_MAS(filename) do
    indexed_grid =
      filename
      |> File.read!()
      |> String.split("\n")
      |> Enum.map(&String.trim/1)
      |> Enum.map(&String.graphemes/1)
      |> Enum.with_index()
      |> Enum.flat_map(fn {line, y} ->
        Enum.with_index(line)
        |> Enum.map(fn {char, x} -> {{x, y}, char} end)
      end)
      |> Enum.into(%{})

    # Get grid dimensions
    max_x = indexed_grid |> Map.keys() |> Enum.map(&elem(&1, 0)) |> Enum.max()
    max_y = indexed_grid |> Map.keys() |> Enum.map(&elem(&1, 1)) |> Enum.max()

    # Check every position as a potential center point (where 'A' would be)
    for x <- 1..(max_x - 1),
        y <- 1..(max_y - 1),
        Map.get(indexed_grid, {x, y}) == "A",
        valid_x_mas?(indexed_grid, {x, y}) do
      {x, y}
    end
    |> length()
  end

  defp valid_word?(grid, {x, y}, {dx, dy}, word) do
    word
    |> String.graphemes()
    |> Enum.with_index()
    |> Enum.all?(fn {char, i} ->
      pos = {x + dx * i, y + dy * i}
      Map.get(grid, pos) == char
    end)
  end

  defp valid_x_mas?(grid, {x, y}) do
    # Must have an 'A' in the center
    center_a = Map.get(grid, {x, y}) == "A"

    # Get the characters at each corner of the X
    # top-left
    tl = Map.get(grid, {x - 1, y - 1})
    # top-right
    tr = Map.get(grid, {x + 1, y - 1})
    # bottom-left
    bl = Map.get(grid, {x - 1, y + 1})
    # bottom-right
    br = Map.get(grid, {x + 1, y + 1})

    # Check if each diagonal contains exactly one M and one S (in either order)
    diagonal1_valid =
      MapSet.new([tl, br]) == MapSet.new(["M", "S"])

    diagonal2_valid =
      MapSet.new([tr, bl]) == MapSet.new(["M", "S"])

    # All conditions must be true
    center_a and diagonal1_valid and diagonal2_valid
  end
end

# part 1

WordSearch.find_words("input.txt")
|> IO.inspect()

# part 2

WordSearch.find_X_MAS("input.txt")
|> IO.inspect()
