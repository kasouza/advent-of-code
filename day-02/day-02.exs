defmodule Day02 do
  defmodule Bag do
    defstruct [:red, :green, :blue]
  end

  defp parse_color(color) do
    case color do
      "red" -> :red
      "green" -> :green
      "blue" -> :blue
      _ -> raise "Invalid color #{color}"
    end
  end

  defp is_color_possible({color, count}, bag) do
    case color do
      :red -> bag.red >= count
      :green -> bag.green >= count
      :blue -> bag.blue >= count
    end
  end

  defp is_possible(subsets, bag) do
    subsets
    |> Enum.map(&is_color_possible(&1, bag))
    |> Enum.all?()
  end

  defp parse_game_id(game) do
    with [id] <- Regex.run(~r/([0-9]+)/, game, capture: :first),
         {id, _rem} when id != nil <- Integer.parse(id) do
      id
    else
      _ -> 0
    end
  end

  defp parse_count(count) do
    case Integer.parse(count) do
      {value, _rem} -> value
      :error -> raise "Invalid count #{count}"
    end
  end

  defp parse_subsets(subsets) do
    subsets
    |> String.split(~r/(,|;)/, trim: true)
    |> Stream.map(&String.split(&1, " ", trim: true))
    |> Enum.map(fn [count, color] ->
      {parse_color(color), parse_count(count)}
    end)
  end

  defp parse_game([game, subsets]) do
    {parse_game_id(game), parse_subsets(subsets)}
  end

  defp calculate_min_count_for_game(subsets) do
    Enum.reduce(
      subsets,
      %{red: 0, green: 0, blue: 0},
      fn {color, count}, min ->
        min_for_color = max(count, min[color])
        Map.put(min, color, min_for_color)
      end
    )
  end

  defp calculate_min_counts(games) do
    games
    |> Enum.map(fn {game_id, subsets} ->
      {game_id, calculate_min_count_for_game(subsets)}
    end)
  end

  def run(list, bag \\ %Bag{}) do
    data =
      list
      |> Stream.map(&String.split(&1, ":", trim: true))
      |> Stream.map(&parse_game/1)

    min_counts = calculate_min_counts(data)
    |> Enum.map(fn {_game_id, %{red: red, green: green, blue: blue}} -> red * green * blue end)
    |> Enum.sum()

    game_id_sum =
      data
      |> Stream.map(fn {game, subsets} -> {game, is_possible(subsets, bag)} end)
      |> Enum.filter(fn {_game, is_possible} -> is_possible end)
      |> Stream.map(fn {game_id, _is_possible} -> game_id end)
      |> Enum.sum()

    %{
      min_counts: min_counts,
      game_id_sum: game_id_sum
    }
  end

  def read_file_and_run(file, bag \\ %Bag{}) do
    File.read!(file)
    |> String.split("\n", trim: true)
    |> run(bag)
  end
end


defmodule Day02Exec do
  def exec() do
    "input.txt"
    |> Day02.read_file_and_run(%Day02.Bag{red: 12, green: 13, blue: 14})
    |> IO.inspect()
  end
end

Day02Exec.exec()
