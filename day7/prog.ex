defmodule BridgeRepair do
  def solve(filename) do
    :ets.new(:memo_table, [:set, :public, :named_table])

    result =
      filename
      |> File.read!()
      |> String.trim()
      |> String.split("\n")
      |> Enum.map(&parse_line/1)
      |> Enum.filter(&valid_equation?/1)
      |> Enum.map(fn {test_val, _nums} -> test_val end)
      |> Enum.sum()

    :ets.delete(:memo_table)
    result
  end

  def parse_line(line) do
    [test_val, nums] = String.split(line, ":")

    numbers =
      nums
      |> String.trim()
      |> String.split(" ")
      |> Enum.map(&String.to_integer/1)

    {String.to_integer(test_val), numbers}
  end

  def valid_equation?({test_val, nums}) do
    evaluate_all_combinations(nums, test_val)
  end

  def evaluate_all_combinations(nums, target) do
    [first | rest] = nums
    evaluate_with_ops(rest, first, target, length(rest))
  end

  def evaluate_with_ops([], current, target, _) do
    current == target
  end

  def evaluate_with_ops([num | rest] = nums, current, target, remaining) do
    key = {nums, current, target}

    case :ets.lookup(:memo_table, key) do
      [{^key, result}] ->
        result

      [] ->
        result =
          cond do
            current > target -> false
            evaluate_with_ops(rest, current + num, target, remaining - 1) -> true
            evaluate_with_ops(rest, current * num, target, remaining - 1) -> true
            true -> false
          end

        :ets.insert(:memo_table, {key, result})
        result
    end
  end

  def solve_part2(filename) do
    filename
    |> File.read!()
    |> String.trim()
    |> String.split("\n")
    |> Enum.map(&parse_line/1)
    |> Enum.filter(&valid_equation_part2?/1)
    |> Enum.map(fn {test_val, _nums} -> test_val end)
    |> Enum.sum()
  end

  def valid_equation_part2?({test_val, nums}) do
    evaluate_all_combinations_part2(nums, test_val)
  end

  def evaluate_all_combinations_part2(nums, target) do
    [first | rest] = nums
    evaluate_with_ops_part2(rest, first, target, length(rest))
  end

  def evaluate_with_ops_part2([], current, target, _) do
    current == target
  end

  def evaluate_with_ops_part2([num | rest], current, target, remaining) do
    cond do
      current > target ->
        false

      evaluate_with_ops_part2(rest, current + num, target, remaining - 1) ->
        true

      current * num <= target and
          evaluate_with_ops_part2(rest, current * num, target, remaining - 1) ->
        true

      # Try concatenation
      (concat_result = String.to_integer("#{current}#{num}")) <= target and
          evaluate_with_ops_part2(rest, concat_result, target, remaining - 1) ->
        true

      true ->
        false
    end
  end
end

# Part 1
BridgeRepair.solve("input.txt")
|> IO.inspect()

# Part 2
BridgeRepair.solve_part2("input.txt")
|> IO.inspect()
