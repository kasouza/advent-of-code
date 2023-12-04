defmodule Token do
  defstruct [:type, :grapheme, :value]

  @spec new(String) :: Token
  def new(grapheme)

  def new(grapheme) do
    case type(grapheme) do
      :int -> %Token{type: :int, grapheme: grapheme, value: int_val(grapheme)}
      :dot -> %Token{type: :dot, grapheme: grapheme, value: nil}
      :sym -> %Token{type: :sym, grapheme: grapheme, value: nil}
    end
  end

  defp type(grapheme) do
    cond do
      grapheme == "." -> :dot
      is_digit(grapheme) -> :int
      true -> :sym
    end
  end

  @spec is_digit(grapheme :: String) :: boolean()
  defp is_digit(grapheme) do
    Integer.parse(grapheme) != :error
  end

  @spec int_val(grapheme :: String) :: Integer | :error
  defp int_val(grapheme) do
    with {value, _remainder} <- Integer.parse(grapheme) do
      value
    end
  end
end

defmodule Cell do
  defstruct [:type, :value]
end

defmodule Schematic do
  @spec tokenize(graphemes :: list(String)) :: list(Token)
  defp tokenize(graphemes) do
    Enum.map(graphemes, &Token.new/1)
  end

  defp evaluate_number(tokens, src_y, src_x, y, x, processed, number)

  defp evaluate_number(
         [%Token{type: :int, value: value} | rest],
         src_y,
         src_x,
         y,
         x,
         processed,
         number
       ) do
    cell = %Cell{type: :number_pointer, value: {src_x, src_y}}
    processed = Map.put(processed, {x, y}, cell)

    evaluate_number(
      rest,
      src_y,
      src_x,
      y,
      x + 1,
      processed,
      number * 10 + value
    )
  end

  defp evaluate_number(_tokens, _src_y, _src_x, y, x, processed, number) do
    {y, x, processed, number}
  end

  defp evaluate(tokens, y, x \\ 0, processed \\ %{})

  defp evaluate([], _y, _x, processed) do
    processed
  end

  defp evaluate([%Token{type: :int, value: value} | rest], y, x, processed) do
    {_y, new_x, new_processed, number} = evaluate_number(rest, y, x, y, x + 1, processed, value)

    rest
    |> Enum.drop(new_x - x - 1)
    |> evaluate(y, new_x, Map.put(new_processed, {x, y}, %Cell{type: :number, value: number}))
  end

  defp evaluate([%Token{type: :dot} | rest], y, x, processed) do
    evaluate(rest, y, x + 1, Map.put(processed, {x, y}, %Cell{type: :empty}))
  end

  defp evaluate([%Token{type: :sym, grapheme: grapheme} | rest], y, x, processed) do
    evaluate(rest, y, x + 1, Map.put(processed, {x, y}, %Cell{type: :sym, value: grapheme}))
  end

  defp parse_line({line, idx}) do
    line
    |> String.graphemes()
    |> tokenize()
    |> evaluate(idx)
  end

  def parse(raw_schematic) do
    process_lines = fn line, processed ->
      Map.merge(parse_line(line), processed)
    end

    raw_schematic
    |> String.split("\n", trim: true)
    |> Enum.with_index()
    |> Enum.reduce(%{}, process_lines)
  end

  def get_index(width, x, y) do
    trunc(y * width + x)
  end

  def coord_from_index(width, idx) do
    x = trunc(rem(idx, width))
    y = trunc(idx / width)
    {x, y}
  end

  def has_symbol_at(_schematic, x, y) when x < 0 or y < 0, do: false

  def has_symbol_at(schematic, x, y)
      when x >= length(schematic.data) or y >= length(schematic.data),
      do: false

  def has_symbol_at(schematic, x, y) do
    idx = get_index(schematic.width, x, y)
    value = Enum.at(schematic.data, idx)

    is_not_dot = value != "."
    is_not_integer = not is_integer(value)

    has_symbol = is_not_dot and is_not_integer

    has_symbol
  end

  def has_neighbor_symbol(schematic, idx) do
    {x, y} = coord_from_index(schematic.width, idx)

    offsets = [
      {-1, -1},
      {0, -1},
      {1, -1},
      {-1, 0},
      nil,
      {1, 0},
      {-1, 1},
      {0, 1},
      {1, 1}
    ]

    Enum.reduce(offsets, true, fn offset, flag ->
      case offset do
        {x_offset, y_offset} -> flag && has_symbol_at(schematic, x + x_offset, y + y_offset)
        nil -> flag
      end
    end)
  end
end

defmodule Day03 do
  @spec get_symbols(schematic :: Map) :: Map
  defp get_symbols(schematic) do
    Enum.filter(schematic, fn {_coord, %Cell{type: type}} -> type == :sym end)
  end

  defp get_gears(schematic) do
    Enum.filter(schematic, fn {_coord, %Cell{type: type, value: value}} -> type == :sym && value == "*" end)
  end

  def get_numbers_following_pointers(cells, schematic, number_cells \\ %{})

  def get_numbers_following_pointers([], _schematic, number_cells) do
    number_cells
  end

  def get_numbers_following_pointers(
        [{_coord, %Cell{type: :number_pointer, value: pointed_coord}} | rest],
        schematic,
        number_cells
      ) do
    cell = Map.get(schematic, pointed_coord)

    get_numbers_following_pointers(
      rest,
      schematic,
      Map.put(number_cells, pointed_coord, cell)
    )
  end

  def get_numbers_following_pointers(
        [{coord, %Cell{type: :number} = cell} | rest],
        schematic,
        number_cells
      ) do
    get_numbers_following_pointers(
      rest,
      schematic,
      Map.put(number_cells, coord, cell)
    )
  end

  @spec get_numbers_near_coord(schematic :: Map, {x :: integer(), y :: integer()}, numbers :: Map) ::
          Map
  defp get_numbers_near_coord(schematic, {x, y}, numbers) do
    offsets = [
      {-1, -1},
      {0, -1},
      {1, -1},
      {-1, 0},
      {1, 0},
      {-1, 1},
      {0, 1},
      {1, 1}
    ]

    map_offsets = fn {x_offset, y_offset} ->
      coord = {x_offset + x, y_offset + y}

      {
        coord,
        Map.get(schematic, coord)
      }
    end

    offsets
    |> Stream.map(map_offsets)
    |> Stream.filter(fn {_coord, cell} -> cell != nil end)
    |> Enum.filter(fn {_coord, %Cell{type: type}} ->
      type == :number or type == :number_pointer
    end)
    |> get_numbers_following_pointers(schematic, numbers)
  end

  @spec get_numbers_near_symbols(schematic :: Map, symbols :: Map) :: Map
  defp get_numbers_near_symbols(schematic, symbols) do
    symbols
    |> Enum.reduce(%{}, fn {coord, _cell}, numbers ->
      get_numbers_near_coord(schematic, coord, numbers)
    end)
  end

  @spec get_gear_ratios(schematic :: Map, symbols :: Map) :: Map
  defp get_gear_ratios(schematic, gears) do
    gears
    |> Enum.map(fn {coord, _cell} ->
      get_numbers_near_coord(schematic, coord, %{})
    end)
    |> Enum.filter(fn map -> map_size(map) == 2 end)
    |> Enum.map(fn numbers ->
      numbers
      |> Stream.map(fn {_coord, %Cell{value: value}} -> value end)
      |> Enum.product()
    end)
  end

  def run(raw_schematic) do
    schematic = Schematic.parse(raw_schematic)
    symbols = get_symbols(schematic)
    gears = get_gears(schematic)

    numbers_near_symbols =
      get_numbers_near_symbols(schematic, symbols)
      |> Enum.map(fn {_coord, %Cell{value: value}} -> value end)
      |> Enum.sum()

    gear_ratios =
      get_gear_ratios(schematic, gears)
      |> Enum.sum()

    {
      numbers_near_symbols,
      gear_ratios,
    }
  end

  def read_file_and_run(file) do
    File.read!(file)
    |> run()
  end
end

defmodule Day03Exec do
  def exec() do
    "input.txt"
    |> Day03.read_file_and_run()
    |> IO.inspect()
  end
end

#ExUnit.start(auto_run: false)

#defmodule Day03Test do
  #use ExUnit.Case

  #test "part 1" do
    #assert 4361 == Day03.run("
      #467..114..
      #...*......
      #..35..633.
      #......#...
      #617*......
      #.....+.58.
      #..592.....
      #......755.
      #...$.**...
      #.664.598..
    #")

    #assert 467 == Day03.run("
      #467..114..
      #...*......
    #")

    #assert 581 == Day03.run("
      #467.114...
      #...*......
    #")

    #assert 581 == Day03.run("
      #$ab**n*j**
      #%467*114**
      #**********
    #")

    #assert 354 == Day03.run("
      #..........
      #....354...
      #....../...
    #")

    #assert 354 == Day03.run("
      #..........
      #....354...
      #......a...
    #")

    #assert 8 == Day03.run("
      #.#............
      #.2..2#..2..#2.
      #........#.....
    #")
  #end
#end

Day03Exec.exec()
