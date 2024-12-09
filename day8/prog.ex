defmodule Antennas do
  def solve_part1(filename) do
    input = File.read!(filename)
    grid = parse_input(input)

    dimensions =
      get_dimensions(grid)

    grid
    |> find_frequencies()
    |> group_by_frequency()
    |> find_antinodes_from_map()
    |> Map.values()
    |> List.flatten()
    |> Enum.uniq()
    |> filter_invalid_antinodes(dimensions)
    |> sort_by_position()
  end

  def solve_part2(filename) do
    input = File.read!(filename)
    grid = parse_input(input)

    dimensions =
      get_dimensions(grid)

    grid
    |> find_frequencies()
    |> group_by_frequency()
    |> find_cascading_antinodes_from_map(dimensions)
    |> Map.values()
    |> List.flatten()
    |> Enum.uniq()
    |> sort_by_position()
  end

  def parse_input(input) do
    input
    |> String.split("\n", trim: true)
    |> Enum.with_index()
    |> Enum.flat_map(fn {line, y} ->
      line
      |> String.graphemes()
      |> Enum.with_index()
      |> Enum.map(fn {char, x} -> {{x, y}, char} end)
    end)
  end

  def get_dimensions(grid) do
    grid
    |> Enum.map(fn {{x, y}, _} -> {x, y} end)
    |> Enum.reduce({0, 0}, fn {x, y}, {max_x, max_y} -> {max(max_x, x), max(max_y, y)} end)
  end

  def find_frequencies(grid) do
    grid
    |> Enum.filter(fn {_pos, char} -> char != "." end)
  end

  def sort_by_position(frequencies) do
    frequencies
    |> Enum.sort_by(fn {x, y} -> {y, x} end)
  end

  def group_by_frequency(frequencies) do
    frequencies
    |> Enum.group_by(
      fn {_pos, freq} -> freq end,
      fn {{x, y}, _freq} -> {x, y} end
    )
    |> Enum.map(fn {freq, positions} -> {freq, positions} end)
    |> Map.new()
  end

  def find_antinodes_from_map(frequencies_map) do
    frequencies_map
    |> Enum.map(fn {freq, positions} -> {freq, find_antinodes(positions)} end)
    |> Map.new()
  end

  def find_cascading_antinodes_from_map(frequencies_map, dimensions) do
    frequencies_map
    |> Enum.map(fn {freq, positions} ->
      {freq, find_cascading_antinodes(positions, dimensions)}
    end)
    |> Map.new()
  end

  def find_antinodes(positions) do
    positions
    |> find_antinodes([])
  end

  def find_cascading_antinodes(positions, dimensions) do
    positions
    |> find_cascading_antinodes([], dimensions)
  end

  def find_antinodes(freq_locs, antinodes) do
    case freq_locs do
      [] ->
        antinodes

      [node | other] ->
        acc =
          Enum.reduce(other, antinodes, fn other_node, acc ->
            {x1, y1} = node
            {x2, y2} = other_node

            dx = x2 - x1
            dy = y2 - y1

            [{x1 - dx, y1 - dy}, {x2 + dx, y2 + dy} | acc]
          end)

        find_antinodes(other, acc)
    end
  end

  def find_cascading_antinodes(freq_locs, antinodes, dimensions) do
    case freq_locs do
      [] ->
        antinodes

      [node | other] ->
        acc =
          Enum.reduce(other, antinodes, fn other_node, acc ->
            {x1, y1} = node
            {x2, y2} = other_node

            dx = x2 - x1
            dy = y2 - y1

            # Generate cascading antinodes in both directions
            before_nodes = generate_cascade_points(x1, y1, -dx, -dy, dimensions)
            after_nodes = generate_cascade_points(x2, y2, dx, dy, dimensions)

            # Include the original frequency points
            [{x1, y1}, {x2, y2}] ++ before_nodes ++ after_nodes ++ acc
          end)

        find_cascading_antinodes(other, acc, dimensions)
    end
  end

  def generate_cascade_points(start_x, start_y, dx, dy, {max_x, max_y}) do
    Stream.iterate(1, &(&1 + 1))
    |> Enum.reduce_while([], fn n, acc ->
      x = start_x + n * dx
      y = start_y + n * dy

      if x >= 0 and x <= max_x and y >= 0 and y <= max_y do
        {:cont, [{x, y} | acc]}
      else
        {:halt, acc}
      end
    end)
  end

  def filter_invalid_antinodes(antinodes, {max_x, max_y}) do
    antinodes
    |> Enum.filter(fn {x, y} ->
      x >= 0 and y >= 0 and x <= max_x and y <= max_y
    end)
  end
end

Antennas.solve_part1("input.txt")
|> Enum.count()
|> IO.inspect(label: "Part 1")

Antennas.solve_part2("input.txt")
|> Enum.count()
|> IO.inspect(label: "Part 2")
