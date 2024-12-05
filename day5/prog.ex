import ExUnit.Assertions

defmodule PrintQueue do
  def print_queue(filename) do
    [rules, messages] =
      filename
      |> File.read!()
      |> String.split("\n\n")
      |> Enum.map(&String.split(&1, "\n"))

    parsed_rules = parse_rules(rules)

    valid_messages =
      messages
      |> Enum.map(&parse_numbers/1)
      |> Enum.filter(&(&1 != [] && !is_nil(&1)))
      |> Enum.filter(&is_valid_message?(&1, parsed_rules))

    formerly_invalid_messages =
      messages
      |> Enum.map(&parse_numbers/1)
      |> Enum.filter(&(&1 != [] && !is_nil(&1)))
      |> Enum.filter(&(!is_valid_message?(&1, parsed_rules)))
      |> Enum.map(&validate_message(&1, parsed_rules))
      |> Enum.map(fn {:ok, valid_message} -> valid_message end)

    {valid_messages, formerly_invalid_messages}
  end

  def get_sum_of_center_numbers(messages) do
    center_indices =
      messages
      |> Enum.map(fn message ->
        message
        |> length()
        |> div(2)
        |> floor()
      end)

    messages
    |> Enum.with_index()
    |> Enum.map(fn {message, idx} ->
      message
      |> Enum.at(Enum.at(center_indices, idx))
    end)
    |> Enum.sum()
  end

  defp validate_message(message, parsed_rules) do
    # Build adjacency list from applicable rules
    applicable_rules = get_applicable_rules(message, parsed_rules)
    graph = build_graph(message, applicable_rules)

    # Try to find a valid ordering using topological sort
    case topological_sort(graph) do
      {:ok, ordered_nodes} ->
        # Convert node indices back to numbers
        {:ok, Enum.map(ordered_nodes, &Enum.at(message, &1))}

      {:error, _} ->
        {:error, "No valid arrangement found"}
    end
  end

  defp parse_rules(rules) do
    rules
    |> Enum.map(fn rule ->
      [before_part, after_part] = String.split(rule, "|")

      {
        parse_numbers(before_part),
        parse_numbers(after_part)
      }
    end)
  end

  defp parse_numbers(str) do
    str
    |> String.trim()
    |> String.split(~r/\s*[,|\s]\s*/)
    |> Enum.reject(&(&1 == ""))
    |> Enum.map(&String.to_integer/1)
  end

  defp is_valid_message?(numbers, rules) do
    # Only check rules where both numbers appear in the message
    rules
    |> Enum.filter(fn {[before_num], [after_num]} ->
      Enum.member?(numbers, before_num) and Enum.member?(numbers, after_num)
    end)
    |> Enum.all?(fn {[before_num], [after_num]} ->
      before_idx = Enum.find_index(numbers, &(&1 == before_num))
      after_idx = Enum.find_index(numbers, &(&1 == after_num))
      # We know both indices exist because we filtered for them
      before_idx < after_idx
    end)
  end

  defp get_applicable_rules(numbers, rules) do
    rules
    |> Enum.filter(fn {[before_num], [after_num]} ->
      Enum.member?(numbers, before_num) and Enum.member?(numbers, after_num)
    end)
  end

  defp build_graph(numbers, rules) do
    # Create a map of number -> index in the message
    number_to_index =
      numbers
      |> Enum.with_index()
      |> Map.new(fn {num, idx} -> {num, idx} end)

    # Convert rules to edges between indices
    edges =
      rules
      |> Enum.map(fn {[before_num], [after_num]} ->
        {Map.get(number_to_index, before_num), Map.get(number_to_index, after_num)}
      end)

    # Build adjacency list
    Enum.reduce(edges, %{}, fn {from, to}, graph ->
      graph
      |> Map.update(from, [to], &[to | &1])
      |> Map.update(to, [], & &1)
    end)
  end

  defp topological_sort(graph) do
    nodes = Map.keys(graph)
    visited = MapSet.new()
    temp = MapSet.new()
    ordered = []

    try do
      {ordered, _visited} =
        Enum.reduce(nodes, {ordered, visited}, fn node, {ordered, visited} ->
          if MapSet.member?(visited, node) do
            {ordered, visited}
          else
            visit(node, graph, visited, temp, ordered)
          end
        end)

      {:ok, Enum.reverse(ordered)}
    catch
      :cycle -> {:error, :cycle_detected}
    end
  end

  defp visit(node, graph, visited, temp, ordered) do
    if MapSet.member?(temp, node) do
      throw(:cycle)
    end

    if MapSet.member?(visited, node) do
      {ordered, visited}
    else
      temp = MapSet.put(temp, node)
      neighbors = Map.get(graph, node, [])

      {ordered, visited} =
        Enum.reduce(neighbors, {ordered, visited}, fn neighbor, {ordered, visited} ->
          visit(neighbor, graph, visited, temp, ordered)
        end)

      {[node | ordered], MapSet.put(visited, node)}
    end
  end
end

{valid_example, formerly_invalid_example} = PrintQueue.print_queue("example.txt")
{valid_messages, formerly_invalid_messages} = PrintQueue.print_queue("input.txt")
# part 1
assert PrintQueue.get_sum_of_center_numbers(valid_example) == 143, "Example part 1 failed"

IO.inspect(PrintQueue.get_sum_of_center_numbers(valid_messages))

# part 2
assert PrintQueue.get_sum_of_center_numbers(formerly_invalid_example) == 123,
       "Example part 2 failed"

IO.inspect(PrintQueue.get_sum_of_center_numbers(formerly_invalid_messages))
