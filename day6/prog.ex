defmodule GuardDetection do
  def parse_input(input) do
    lines = String.split(input, "\n", trim: true)
    height = length(lines)
    width = String.length(hd(lines))

    grid =
      for {line, y} <- Enum.with_index(lines),
          {char, x} <- String.graphemes(line) |> Enum.with_index(),
          into: %{} do
        {{x, y}, char}
      end

    {start_pos, direction} = find_start(grid)
    {grid, start_pos, direction, width, height}
  end

  def find_start(grid) do
    {pos, char} = Enum.find(grid, fn {_pos, char} -> char in ["^", ">", "<", "v"] end)

    direction =
      case char do
        "^" -> {0, -1}
        ">" -> {1, 0}
        "<" -> {-1, 0}
        "v" -> {0, 1}
      end

    {pos, direction}
  end

  def solve(filename) do
    input = File.read!(filename)
    {grid, start_pos, direction, width, height} = parse_input(input)
    grid = Map.put(grid, start_pos, ".")

    visited = move(grid, start_pos, direction, width, height, MapSet.new([start_pos]))
    print_path(grid, visited, width, height)
    MapSet.size(visited)
  end

  def move(grid, {x, y} = pos, dir, width, height, visited) do
    next_pos = {x + elem(dir, 0), y + elem(dir, 1)}
    {next_x, next_y} = next_pos

    cond do
      # Check if next position is out of bounds
      next_x < 0 or next_y < 0 or next_x >= width or next_y >= height ->
        visited

      # Hit obstacle, turn right
      Map.get(grid, next_pos) == "#" ->
        new_dir = turn_right(dir)
        move(grid, pos, new_dir, width, height, visited)

      # Move forward
      true ->
        move(grid, next_pos, dir, width, height, MapSet.put(visited, next_pos))
    end
  end

  def turn_right({dx, dy}) do
    case {dx, dy} do
      # up -> right
      {0, -1} -> {1, 0}
      # right -> down
      {1, 0} -> {0, 1}
      # down -> left
      {0, 1} -> {-1, 0}
      # left -> up
      {-1, 0} -> {0, -1}
    end
  end

  def print_path(grid, visited, width, height) do
    IO.puts("\nPath taken:")

    for y <- 0..(height - 1) do
      for x <- 0..(width - 1) do
        char =
          cond do
            MapSet.member?(visited, {x, y}) -> "X"
            Map.get(grid, {x, y}) == "#" -> "#"
            true -> "."
          end

        IO.write(char)
      end

      IO.puts("")
    end

    IO.puts("\n")
  end

  def solve_part2(filename) do
    input = File.read!(filename)
    {grid, start_pos, direction, width, height} = parse_input(input)
    grid = Map.put(grid, start_pos, ".")

    # Get the original path and track the direction at each point
    {original_path, path_directions} =
      move_with_directions(grid, start_pos, direction, width, height)

    # Consider all positions in the path except the start position
    empty_spaces =
      MapSet.to_list(original_path)
      |> Enum.filter(fn pos -> pos != start_pos end)

    # Process positions in chunks
    chunk_size = 10

    # this takes so long LMAO but it works :eyes:
    loop_positions =
      empty_spaces
      |> Enum.chunk_every(chunk_size)
      |> Enum.reduce([], fn chunk, acc ->
        chunk_results =
          Task.async_stream(
            chunk,
            fn pos ->
              {pos, creates_loop?(grid, start_pos, direction, width, height, pos)}
            end,
            timeout: 5000,
            max_concurrency: System.schedulers_online()
          )
          |> Enum.reduce([], fn
            {:ok, {pos, true}}, acc -> [pos | acc]
            _, acc -> acc
          end)

        acc ++ chunk_results
      end)

    # Print first few solutions
    if length(loop_positions) > 0 do
      IO.puts("\nFirst few solutions:")

      Enum.take(loop_positions, 3)
      |> Enum.each(fn pos ->
        IO.puts("\nPossible obstacle at position #{inspect(pos)}:")
        print_loop_path(grid, start_pos, direction, width, height, pos)
      end)
    end

    length(loop_positions)
  end

  def move_with_directions(grid, start_pos, direction, width, height) do
    move_with_directions_helper(
      grid,
      start_pos,
      direction,
      width,
      height,
      MapSet.new([start_pos]),
      %{start_pos => direction}
    )
  end

  def move_with_directions_helper(grid, {x, y} = pos, dir, width, height, visited, directions) do
    next_pos = {x + elem(dir, 0), y + elem(dir, 1)}
    {next_x, next_y} = next_pos

    cond do
      # Check if next position is out of bounds
      next_x < 0 or next_y < 0 or next_x >= width or next_y >= height ->
        {visited, directions}

      # Hit obstacle, turn right
      Map.get(grid, next_pos) == "#" ->
        new_dir = turn_right(dir)

        move_with_directions_helper(
          grid,
          pos,
          new_dir,
          width,
          height,
          visited,
          Map.put(directions, pos, new_dir)
        )

      # Move forward
      true ->
        move_with_directions_helper(
          grid,
          next_pos,
          dir,
          width,
          height,
          MapSet.put(visited, next_pos),
          Map.put(directions, next_pos, dir)
        )
    end
  end

  def creates_loop?(grid, start_pos, direction, width, height, obstacle_pos) do
    # Add the test obstacle
    test_grid = Map.put(grid, obstacle_pos, "#")

    # Track visited positions with their directions
    visited = MapSet.new()

    # Helper function to detect loops
    detect_loop(test_grid, start_pos, direction, width, height, visited, start_pos)
  end

  def detect_loop(grid, pos, dir, width, height, visited, start_pos) do
    detect_loop_helper(grid, pos, dir, width, height, MapSet.new(), 0, width * height * 4)
  end

  def detect_loop_helper(grid, pos, dir, width, height, visited, steps, max_steps) do
    state = {pos, dir}

    cond do
      # If we've seen this state before, it's a loop
      MapSet.member?(visited, state) ->
        # Only count it as a loop if we've taken enough steps
        steps > 4

      # If we're out of bounds or hit max steps, not a loop
      steps >= max_steps or
        elem(pos, 0) < 0 or elem(pos, 1) < 0 or
        elem(pos, 0) >= width or elem(pos, 1) >= height ->
        false

      true ->
        visited = MapSet.put(visited, state)
        next_pos = {elem(pos, 0) + elem(dir, 0), elem(pos, 1) + elem(dir, 1)}

        case Map.get(grid, next_pos) do
          "#" ->
            # Hit obstacle, turn right and continue
            new_dir = turn_right(dir)
            detect_loop_helper(grid, pos, new_dir, width, height, visited, steps + 1, max_steps)

          nil ->
            # Out of bounds
            false

          _ ->
            # Move forward
            detect_loop_helper(grid, next_pos, dir, width, height, visited, steps + 1, max_steps)
        end
    end
  end

  def print_loop_path(grid, start_pos, direction, width, height, obstacle_pos) do
    test_grid = Map.put(grid, obstacle_pos, "#")
    max_steps = width * height * 4

    visited =
      trace_path_with_steps(
        test_grid,
        start_pos,
        direction,
        width,
        height,
        MapSet.new(),
        0,
        max_steps
      )

    for y <- 0..(height - 1) do
      for x <- 0..(width - 1) do
        char =
          cond do
            {x, y} == obstacle_pos -> "O"
            MapSet.member?(visited, {x, y}) -> "+"
            Map.get(grid, {x, y}) == "#" -> "#"
            true -> "."
          end

        IO.write(char)
      end

      IO.puts("")
    end
  end

  def trace_path_with_steps(_grid, _pos, _dir, _width, _height, visited, steps, max_steps)
      when steps >= max_steps,
      do: visited

  def trace_path_with_steps(grid, pos, dir, width, height, visited, steps, max_steps) do
    visit_key = {pos, dir}

    if MapSet.member?(visited, visit_key) or
         elem(pos, 0) < 0 or elem(pos, 1) < 0 or
         elem(pos, 0) >= width or elem(pos, 1) >= height do
      visited
    else
      visited = MapSet.put(visited, pos)
      next_pos = {elem(pos, 0) + elem(dir, 0), elem(pos, 1) + elem(dir, 1)}

      if Map.get(grid, next_pos) == "#" do
        new_dir = turn_right(dir)
        trace_path_with_steps(grid, pos, new_dir, width, height, visited, steps + 1, max_steps)
      else
        trace_path_with_steps(grid, next_pos, dir, width, height, visited, steps + 1, max_steps)
      end
    end
  end

  # Helper function to get adjacent positions
  def adjacent_positions({x, y}) do
    [
      {x + 1, y},
      {x - 1, y},
      {x, y + 1},
      {x, y - 1}
    ]
  end
end

# part 1
IO.puts("Part 1 Result: #{GuardDetection.solve("input.txt")}")

# part 2
IO.puts("\nPart 2 Result: #{GuardDetection.solve_part2("input.txt")}")
