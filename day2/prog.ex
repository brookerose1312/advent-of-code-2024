defmodule ReportParser do
  def parse_file(filename) do
    File.read!(filename)
    |> String.split("\n", trim: true)
    |> Enum.map(fn line ->
      String.split(line, " ", trim: true)
      |> Enum.map(&String.to_integer/1)
    end)
  end

  def report_is_safe?(report) do
    # Check if numbers are consistently increasing
    increasing =
      Enum.chunk_every(report, 2, 1, :discard)
      |> Enum.all?(fn [a, b] -> b > a end)

    # Check if numbers are consistently decreasing
    decreasing =
      Enum.chunk_every(report, 2, 1, :discard)
      |> Enum.all?(fn [a, b] -> b < a end)

    # Get difference between numbers
    safe_change =
      Enum.chunk_every(report, 2, 1, :discard)
      |> Enum.all?(fn [a, b] -> abs(b - a) >= 1 && abs(b - a) <= 3 end)

    (increasing || decreasing) && safe_change
  end
end

reports = ReportParser.parse_file("input.txt")

# part 1
safe_reports =
  Enum.filter(reports, &ReportParser.report_is_safe?/1)

IO.inspect(length(safe_reports))

# part 2
safe_dampened_reports =
  Enum.filter(reports, fn report ->
    Enum.with_index(report)
    |> Enum.any?(fn {_elem, index} ->
      List.delete_at(report, index)
      |> ReportParser.report_is_safe?()
    end)
  end)

IO.inspect(length(safe_dampened_reports))
