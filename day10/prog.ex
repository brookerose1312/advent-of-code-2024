import ExUnit.Assertions

defmodule Hiking do
  def solve_part1(input) do
    grid = parse_input(input)
    starting_points = find_points(grid, 0)

    starting_points
    |> Enum.map(fn start -> count_reachable_endpoints(grid, start) end)
    |> Enum.sum()
  end

  def parse_input(filename) do
    filename
    |> File.read!()
    |> String.split("\n", trim: true)
    |> Enum.map(&String.graphemes/1)
    |> Enum.map(fn row ->
      Enum.map(row, fn char ->
        case char do
          "." -> :no_path
          num -> String.to_integer(num)
        end
      end)
    end)
    |> Enum.with_index()
    |> Enum.reduce(%{}, fn {row, y}, acc ->
      row
      |> Enum.with_index()
      |> Enum.reduce(acc, fn {val, x}, acc2 ->
        Map.put(acc2, {x, y}, val)
      end)
    end)
  end

  def find_points(grid, target_value) do
    grid
    |> Enum.filter(fn {_pos, val} -> val != :no_path && val == target_value end)
    |> Enum.map(fn {pos, _} -> pos end)
  end

  def count_reachable_endpoints(grid, start) do
    endpoints = find_points(grid, 9)

    find_reachable_endpoints(grid, start, endpoints, MapSet.new())
    |> MapSet.size()
  end

  def find_reachable_endpoints(grid, current, endpoints, visited) do
    cond do
      current in endpoints ->
        MapSet.new([current])

      true ->
        next_positions = get_valid_moves(grid, current, visited)

        next_positions
        |> Enum.reduce(MapSet.new(), fn pos, acc ->
          MapSet.union(
            acc,
            find_reachable_endpoints(grid, pos, endpoints, MapSet.put(visited, current))
          )
        end)
    end
  end

  def get_valid_moves(grid, {x, y}, visited) do
    current_value = Map.get(grid, {x, y})

    [
      {x + 1, y},
      {x - 1, y},
      {x, y + 1},
      {x, y - 1}
    ]
    |> Enum.filter(fn pos ->
      next_value = Map.get(grid, pos)

      pos not in visited &&
        next_value != nil &&
        next_value != :no_path &&
        next_value == current_value + 1
    end)
  end

  def solve_part2(input) do
    grid = parse_input(input)
    starting_points = find_points(grid, 0)

    starting_points
    |> Enum.map(fn start -> count_unique_paths(grid, start) end)
    |> Enum.sum()
  end

  def count_unique_paths(grid, start) do
    endpoints = find_points(grid, 9)

    find_all_paths(grid, start, endpoints, MapSet.new())
    |> length()
  end

  def find_all_paths(grid, current, endpoints, visited) do
    cond do
      current in endpoints ->
        [MapSet.put(visited, current)]

      true ->
        next_positions = get_valid_moves(grid, current, visited)

        next_positions
        |> Enum.flat_map(fn pos ->
          find_all_paths(grid, pos, endpoints, MapSet.put(visited, current))
        end)
    end
  end
end

assert Hiking.solve_part1("example.txt") == 36, "Example part 1 failed"
assert Hiking.solve_part2("example.txt") == 81, "Example part 2 failed"

Hiking.solve_part1("input.txt")
|> IO.inspect(label: "Part 1")

Hiking.solve_part2("input.txt")
|> IO.inspect(label: "Part 2")
