defmodule TablePrint do
  def print(table, {no_of_row, no_of_column}, cell_width) when length(table) == no_of_row do
    # https://www.unicode.org/charts/PDF/U2500.pdf

    print_separator(no_of_column, cell_width, :top)

    1..no_of_row
    |> Enum.each(fn row ->
      # cell_strings = List.duplicate(to_string(:o), size)
      cell_strings = Enum.at(table, row - 1)
      print_line(no_of_column, cell_width, cell_strings)

      if row != no_of_row do
        print_separator(no_of_column, cell_width, :middle)
      end
    end)

    print_separator(no_of_column, cell_width, :bottom)
  end

  defp print_line(no_of_column, column_width, fill_string)
       when length(fill_string) == no_of_column do
    vertical_line = <<0x2502::utf8>>
    IO.write(vertical_line)

    1..no_of_column
    |> Enum.each(fn col ->
      print_cell(column_width, Enum.at(fill_string, col - 1))
      IO.write(vertical_line)
    end)

    IO.write("\n")
  end

  defp print_cell(column_width, fill_string) when is_binary(fill_string) do
    char_length = String.length(fill_string)

    if column_width >= char_length do
      pad = column_width - char_length
      left_pad = div(pad, 2)
      right_pad = pad - left_pad

      IO.write(String.duplicate(" ", left_pad))
      IO.write(fill_string)
      IO.write(String.duplicate(" ", right_pad))
    else
      throw("TODO: ")
    end
  end

  defp print_separator(no_of_column, column_width, :middle) do
    # middle
    left_char = <<0x251C::utf8>>
    fill_char = <<0x2500::utf8>>
    separator = _cross = <<0x253C::utf8>>
    right_char = <<0x2524::utf8>>

    print_separator(
      %{column_width: column_width, no_of_column: no_of_column},
      {left_char, fill_char, separator, right_char}
    )
  end

  defp print_separator(no_of_column, column_width, :bottom) do
    # bottom
    left_char = <<0x2514::utf8>>
    fill_char = <<0x2500::utf8>>
    separator = <<0x2534::utf8>>
    right_char = <<0x2518::utf8>>

    print_separator(
      %{column_width: column_width, no_of_column: no_of_column},
      {left_char, fill_char, separator, right_char}
    )
  end

  defp print_separator(no_of_column, column_width, :top) do
    # top
    left_char = <<0x250C::utf8>>
    fill_char = <<0x2500::utf8>>
    separator = <<0x252C::utf8>>
    right_char = <<0x2510::utf8>>

    print_separator(
      %{column_width: column_width, no_of_column: no_of_column},
      {left_char, fill_char, separator, right_char}
    )
  end

  defp print_separator(
         %{column_width: column_width, no_of_column: no_of_column} = _dimension,
         {_, _, _, _} = characters
       ) do
    {left_char, line_character, separator, right_char} = characters
    IO.write(left_char)
    middle_string = String.duplicate(line_character, column_width)

    1..no_of_column
    |> Enum.each(fn col ->
      IO.write(middle_string)

      if col != no_of_column do
        IO.write(separator)
      end
    end)

    IO.write(right_char)
    IO.write("\n")
  end
end
