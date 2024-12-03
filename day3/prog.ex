defmodule MemParser do
  def parse_file(filename, allow_disable? \\ false) do
    filename
    |> File.read!()
    |> find_multiplications(allow_disable?)
  end

  def find_multiplications(content, allow_disable? \\ false) do
    if allow_disable? do
      # Split content into tokens we care about
      tokens =
        Regex.scan(~r/(?:don't\(\)|do\(\)|mul\(\d+,\d+\))/, content)
        |> List.flatten()

      # Process tokens in sequence, tracking enabled state
      {_, results} =
        Enum.reduce(tokens, {true, []}, fn token, {enabled?, results} ->
          case token do
            "don't()" -> {false, results}
            "do()" -> {true, results}
            mul_call when enabled? -> {enabled?, results ++ [mul_call]}
            _ -> {enabled?, results}
          end
        end)

      results
    else
      Regex.scan(~r/mul\(\d+,\d+\)/, content)
      |> List.flatten()
    end
  end

  def sum_muls(mul_calls) do
    Enum.map(mul_calls, fn mul_call ->
      String.split(mul_call, "mul(")
      |> List.last()
      |> String.trim_trailing(")")
      |> String.split(",")
      |> Enum.map(&String.to_integer/1)
    end)
    |> Enum.map(fn [a, b] -> a * b end)
    |> Enum.sum()
  end
end

mul_calls = MemParser.parse_file("input.txt")

# part 1

sum_of_mul = MemParser.sum_muls(mul_calls)

IO.puts(sum_of_mul)

# part 2

potentially_disabled_mul_calls = MemParser.parse_file("input.txt", true)

sum_of_part_2_mul = MemParser.sum_muls(potentially_disabled_mul_calls)

IO.puts(sum_of_part_2_mul)
