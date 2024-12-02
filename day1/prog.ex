defmodule NumberParser do
  def parse_file(filename) do
    File.read!(filename)
    |> String.split("\n", trim: true)
    |> Enum.reduce({[], []}, fn line, {first_nums, second_nums} ->
      # each line looks like "num1   num2"
      case String.split(line, "   ") do
        [first, second] ->
          {
            [String.to_integer(first) | first_nums],
            [String.to_integer(second) | second_nums]
          }

        # Skip invalid lines
        _ ->
          {first_nums, second_nums}
      end
    end)
    |> then(fn {first, second} ->
      {Enum.reverse(first), Enum.reverse(second)}
    end)
    |> then(fn {first, second} ->
      {Enum.sort(first), Enum.sort(second)}
    end)
  end
end

# part 1
{first_numbers, second_numbers} = NumberParser.parse_file("input.txt")

total_distance =
  Enum.zip(first_numbers, second_numbers)
  |> Enum.reduce(0, fn {first, second}, acc ->
    acc + abs(first - second)
  end)

IO.inspect(total_distance)

# part 2
similarity_score =
  Enum.reduce(first_numbers, 0, fn first_num, acc ->
    occurrences = Enum.count(second_numbers, fn second_num -> second_num == first_num end)
    acc + first_num * occurrences
  end)

IO.inspect(similarity_score)
