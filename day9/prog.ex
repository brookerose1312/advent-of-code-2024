import ExUnit.Assertions

defmodule FileSystem do
  require Integer

  def solve_part1(filename) do
    input = File.read!(filename)

    parse_input(input)
    |> defrag_filesys()
    |> IO.inspect(label: "Defragged")
    |> calculate_checksum()
  end

  def solve_part2(filename) do
    input = File.read!(filename)

    parse_input(input)
    |> defrag_filesys_whole_files_only()
    |> IO.inspect(label: "Defragged")
    |> calculate_checksum()
  end

  defp parse_input(input) do
    input
    |> String.graphemes()
    |> Enum.filter(&(&1 != "\n"))
    |> create_filesys(0, 0, [])
    |> IO.inspect(label: "Filesys")
  end

  defp create_filesys(input, index, file_id, filesys) do
    case input do
      [] ->
        filesys

      [char | rest] ->
        size =
          char
          |> String.to_integer()

        if Integer.is_even(index) do
          # Add size copies of index to filesys
          create_filesys(rest, index + 1, file_id + 1, filesys ++ List.duplicate(file_id, size))
        else
          create_filesys(rest, index + 1, file_id, filesys ++ List.duplicate(".", size))
        end
    end
  end

  defp defrag_filesys(filesys) do
    filesys
    |> defrag_step()
  end

  defp defrag_step(filesys) do
    case find_move(filesys) do
      # No more moves possible
      nil ->
        filesys

      {from_idx, to_idx} ->
        # Perform the swap
        filesys
        |> List.update_at(to_idx, fn _ -> Enum.at(filesys, from_idx) end)
        |> List.update_at(from_idx, fn _ -> "." end)
        # Continue defragging
        |> defrag_step()
    end
  end

  defp find_move(filesys) do
    # Find rightmost number and leftmost dot
    right_num_idx =
      Enum.find_index(Enum.reverse(filesys), &(&1 != ".")) |> then(&(length(filesys) - 1 - &1))

    left_dot_idx = Enum.find_index(filesys, &(&1 == "."))

    case {left_dot_idx, right_num_idx} do
      # No dots found
      {nil, _} -> nil
      # No numbers found
      {_, nil} -> nil
      {dot_idx, num_idx} when dot_idx < num_idx -> {num_idx, dot_idx}
      # No valid moves
      _ -> nil
    end
  end

  defp defrag_filesys_whole_files_only(filesys) do
    # Get unique file IDs in descending order (excluding dots)
    file_ids =
      filesys
      |> Enum.reject(&(&1 == "."))
      |> Enum.uniq()
      |> Enum.sort(:desc)

    # Try to move each file once
    Enum.reduce(file_ids, filesys, fn file_id, fs ->
      move_file_if_possible(fs, file_id)
    end)
  end

  defp move_file_if_possible(filesys, file_id) do
    # Find the file chunk and first available space
    chunks =
      filesys
      |> Enum.with_index()
      |> Enum.chunk_by(fn {val, _} -> val end)
      |> Enum.map(fn chunk ->
        [{val, start_idx} | _] = chunk
        {val, start_idx, length(chunk)}
      end)

    # Find the chunk for this file_id
    file_chunk = Enum.find(chunks, fn {val, _, _} -> val == file_id end)

    case file_chunk do
      nil ->
        filesys

      {_, file_start, file_size} ->
        # Find first dot sequence that's large enough
        dot_chunk =
          chunks
          |> Enum.find(fn
            {".", _, space_size} -> space_size >= file_size
            _ -> false
          end)

        case dot_chunk do
          nil ->
            filesys

          {".", space_start, _} ->
            if file_start > space_start do
              # Move the file
              move_file(filesys, file_id, file_start, file_size, space_start)
            else
              # Can't move this file
              filesys
            end
        end
    end
  end

  defp move_file(filesys, file_val, file_start, file_size, space_start) do
    # Move the file
    filesys
    |> then(fn fs ->
      # Place the file in the new location
      Enum.reduce(0..(file_size - 1), fs, fn i, acc ->
        List.update_at(acc, space_start + i, fn _ -> file_val end)
      end)
    end)
    |> then(fn fs ->
      # Replace old location with dots
      Enum.reduce(0..(file_size - 1), fs, fn i, acc ->
        List.update_at(acc, file_start + i, fn _ -> "." end)
      end)
    end)
  end

  defp calculate_checksum(filesys) do
    filesys
    |> Enum.with_index()
    |> Enum.reduce(0, fn {value, index}, acc ->
      if value == "." do
        acc
      else
        acc + index * value
      end
    end)
  end
end

# test
assert FileSystem.solve_part1("example.txt") == 1928, "Example part 1 failed"
assert FileSystem.solve_part2("example.txt") == 2858, "Example part 2 failed"

# part 1

FileSystem.solve_part1("input.txt")
|> IO.inspect(label: "Part 1")

# part 2

FileSystem.solve_part2("input.txt")
|> IO.inspect(label: "Part 2")

# i could probably make this faster but i don't care enough to do so
