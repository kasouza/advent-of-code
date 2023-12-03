defmodule Day01 do
  @regex ~r/(?=(\d)|(one)|(two)|(three)|(four)|(five)|(six)|(seven)|(eight)|(nine))/i
  @replacements_map %{
    "1" => 1,
    "2" => 2,
    "3" => 3,
    "4" => 4,
    "5" => 5,
    "6" => 6,
    "7" => 7,
    "8" => 8,
    "9" => 9,
    "one" => 1,
    "two" => 2,
    "three" => 3,
    "four" => 4,
    "five" => 5,
    "six" => 6,
    "seven" => 7,
    "eight" => 8,
    "nine" => 9
  }

  defp digits_with_idx(string) do
    matches = Regex.scan(@regex, string, return: :index)

    matches
    |> Stream.flat_map(fn val -> val end)
    |> Stream.map(fn {idx, len} -> {idx, @replacements_map[String.slice(string, idx, len)]} end)
    |> Stream.filter(fn {_idx, val} -> val != nil end)
    |> Enum.sort(fn {idx1, _value}, {idx2, _value2} -> idx1 <= idx2 end)
    |> Enum.map(fn {_idx, val} -> val end)
  end

  defp calculate_calibration(string) do
    case digits_with_idx(string) do
      [] -> 0
      list -> List.first(list) * 10 + List.last(list)
    end
  end

  def run(list) do
    list
    |> Stream.map(&calculate_calibration/1)
    |> Enum.sum()
  end

  def read_file_and_run(file) do
    File.read!(file)
    |> String.split("\n")
    |> run()
  end
end

"input.txt"
|> Day01.read_file_and_run()
|> IO.inspect()
