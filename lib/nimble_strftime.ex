defmodule NimbleStrftime do
  @moduledoc """
  Library for simple datetime formatting based on the strftime format found on UNIX-like systems

  ## Formatting syntax
  The formatting syntax for strftime is a sequence of characters in the following format
  `%<padding><width><format>`
  * `%`: indicates the start of a formatted section
  * `<padding>`: is an option to set the padding of the formatted section and accepts the following options
  * `<width>`: a number indicating the minimun size of the formatted section
  * `<format>`: the format iself, dictates what info is shown on this formatted section

  ### Accepted padding options
    * `-`: no padding, removes all padding from the format
    * `_`: pad with spaces
    * `0`: pad with zeroes

  ### Accepted formats
  the accepted formats are as follows, any other character will be interpreted literally and won't be formatted
  * `%` -  Literally just the `%` char
  * `a` -  Abbreviated name of the day
  * `A` -  Name of the day
  * `b` -  Abbreviated name of the month
  * `B` -  Name of the month
  * `c` -  Preferred datetime representation
  * `d` -  Day of the month
  * `f` -  Microseconds
  * `H` -  Hour in Military Time(24 hours)
  * `I` -  Hour in Regular Time(12 hours)
  * `j` -  Day of the year
  * `m` -  Month
  * `M` -  Minute
  * `p` -  Period of the day("AM" and "PM") in uppercase
  * `P` -  Period of the day("am" and "pm") in lowercase
  * `q` -  Quarter of the year
  * `S` -  Second
  * `u` -  Day of the week
  * `x` -  Preferred date
  * `X` -  Preferred time
  * `y` -  Year in two digits
  * `Y` -  Year
  * `z` -  Time zone offset from UTC(blank if in naive time)
  * `Z` -  Time zone abbreviation(Blank if naive)
  """
  @default_options %{
    preferred_date: "%Y-%m-%d",
    preferred_time: "%H:%M:%S",
    preferred_datetime: "%Y-%m-%d %H:%M:%S",
    am_pm_names: {"am", "pm"},
    month_names:
      ~w(January February March April May June July August September October November December),
    day_of_week_names: ~w(Monday Tuesday Wednesday Thursday Friday Saturday Sunday),
    abbreviation_size: 3,
    preferred_datetime_invoked: false,
    preferred_date_invoked: false,
    preferred_time_invoked: false
  }

  @doc """
  Formats received datetime into a String

  ## Options

  * `:preferred_datetime` - a string for the preferred format to show datetimes,
    it can't contain the `%c` format and defaults to `"%Y-%m-%d %H:%M:%S"`
    if the option is not received

  * `:preferred_date` - a string for the preferred format to show dates,
    it can't contain the `%x` format and defaults to `"%Y-%m-%d"`
    if the option is not received

  * `:preferred_time` - a string for the preferred format to show times,
    it can't contain the `%X` format and defaults to `"%H:%M:%S"`
    if the option is not received

  * `:am_pm_names` - a tuple for the terms to be used as `am` and `pm`, respectively
    it defaults to `{"am", "pm"}` if the option is not received

  *  `:month_names` - a list with month names in order, defaults to a list of
    month names in english if the option is not received

  * `:day_of_week_names` - a list with the name of the days in the week, defaults
    to the name of the days of week in english if the option is not received

  * `:abbreviation_size` - number of characters shown in abbreviated
    month and week day names, if the option is not received the default of 3 is set
  """
  @spec format(
          Date.t() | Time.t() | NaiveDateTime.t() | DateTime.t(),
          String.t(),
          list({atom(), any()})
        ) :: String.t()
  def format(date_or_time_or_datetime, string_format, user_options \\ []) do
    parse(
      string_format,
      date_or_time_or_datetime,
      options(user_options)
    )
    |> IO.iodata_to_binary()
  end

  defp parse(data, datetime, format_options, acc \\ [])

  defp parse("", _datetime, _format_options, acc),
    do: acc |> Enum.reverse()

  defp parse("%" <> rest, datetime, format_options, acc),
    do: parse_modifiers(rest, nil, nil, [datetime, format_options, acc])

  defp parse(<<char::binary-1, rest::binary>>, datetime, format_options, acc) do
    parse(rest, datetime, format_options, [char | acc])
  end

  @spec parse_modifiers(
          String.t(),
          integer() | nil,
          String.t() | nil,
          list()
        ) :: list()
  defp parse_modifiers("-" <> rest, width, nil, parser_data) do
    parse_modifiers(rest, width, "-", parser_data)
  end

  defp parse_modifiers("0" <> rest, width, nil, parser_data) do
    parse_modifiers(rest, width, "0", parser_data)
  end

  defp parse_modifiers("_" <> rest, width, nil, parser_data) do
    parse_modifiers(
      rest,
      width,
      " ",
      parser_data
    )
  end

  defp parse_modifiers(<<digit, rest::binary>>, width, pad, parser_data)
       when digit in ?0..?9 do
    new_width =
      case pad do
        "-" -> 0
        _ -> (width || 0) * 10 + (digit - ?0)
      end

    parse_modifiers(rest, new_width, pad, parser_data)
  end

  defp parse_modifiers(rest, width, pad, [datetime, format_options, acc]) do
    format_modifiers(rest, width, pad, datetime, format_options, acc)
  end

  defp am_pm(hour, format_options) when hour > 11 do
    elem(format_options.am_pm_names, 1)
  end

  defp am_pm(hour, format_options) when hour <= 11 do
    elem(format_options.am_pm_names, 0)
  end

  defp month_name(index, format_options) when index > 0 and index < 13 do
    Enum.at(format_options.month_names, index - 1)
  end

  defp month_name_abbreviated(index, format_options) do
    String.slice(month_name(index, format_options), 0..(format_options.abbreviation_size - 1))
  end

  defp day_of_week_name(index, format_options) when index > 0 and index < 8 do
    Enum.at(format_options.day_of_week_names, index - 1)
  end

  defp day_of_week_name_abbreviated(index, format_options) do
    String.slice(
      day_of_week_name(index, format_options),
      0..(format_options.abbreviation_size - 1)
    )
  end

  defp default_pad(format) do
    case format do
      format when format in ~w(a A b B p P Z) -> " "
      _ -> "0"
    end
  end

  defp default_width(format) do
    case format do
      format when format in ~w(d H I m M S u y) -> 2
      "j" -> 3
      format when format in ~w(Y z) -> 4
      _ -> 0
    end
  end

  # set default padding if none was specfied
  defp format_modifiers(
         stream = <<format::binary-1, _rest::binary>>,
         width,
         nil,
         datetime,
         format_options,
         acc
       ) do
    format_modifiers(stream, width, default_pad(format), datetime, format_options, acc)
  end

  # set default width if none was specified
  defp format_modifiers(
         stream = <<format::binary-1, _rest::binary>>,
         nil,
         pad,
         datetime,
         format_options,
         acc
       ) do
    format_modifiers(stream, default_width(format), pad, datetime, format_options, acc)
  end

  # Literally just %
  defp format_modifiers("%" <> rest, width, pad, datetime, format_options, acc) do
    parse(rest, datetime, format_options, [String.pad_leading("%", width, pad) | acc])
  end

  # Abbreviated name of day
  defp format_modifiers("a" <> rest, width, pad, datetime, format_options, acc) do
    result =
      datetime
      |> Date.day_of_week()
      |> day_of_week_name_abbreviated(format_options)
      |> String.pad_leading(width, pad)

    parse(rest, datetime, format_options, [result | acc])
  end

  # Full name of day
  defp format_modifiers("A" <> rest, width, pad, datetime, format_options, acc) do
    result =
      datetime
      |> Date.day_of_week()
      |> day_of_week_name(format_options)
      |> String.pad_leading(width, pad)

    parse(rest, datetime, format_options, [result | acc])
  end

  # Abbreviated month name
  defp format_modifiers("b" <> rest, width, pad, datetime, format_options, acc) do
    result =
      datetime.month
      |> month_name_abbreviated(format_options)
      |> String.pad_leading(width, pad)

    parse(rest, datetime, format_options, [result | acc])
  end

  # Full month name
  defp format_modifiers("B" <> rest, width, pad, datetime, format_options, acc) do
    result = datetime.month |> month_name(format_options) |> String.pad_leading(width, pad)

    parse(rest, datetime, format_options, [result | acc])
  end

  # Preferred date+time representation
  defp format_modifiers(
         "c" <> _rest,
         _width,
         _pad,
         _datetime,
         %{preferred_datetime_invoked: true},
         _acc
       ) do
    raise RuntimeError,
          "tried to format preferred_datetime within another preferred_datetime format"
  end

  defp format_modifiers("c" <> rest, width, pad, datetime, format_options, acc) do
    result =
      format_options.preferred_datetime
      |> parse(datetime, %{format_options | preferred_datetime_invoked: true})
      |> pad_preferred(width, pad)

    parse(rest, datetime, format_options, [result | acc])
  end

  # Day of the month
  defp format_modifiers("d" <> rest, width, pad, datetime, format_options, acc) do
    result = datetime.day |> to_string() |> String.pad_leading(width, pad)
    parse(rest, datetime, format_options, [result | acc])
  end

  # Microseconds
  defp format_modifiers("f" <> rest, width, pad, datetime, format_options, acc) do
    result = datetime.microsecond |> elem(0) |> to_string() |> String.pad_leading(width, pad)
    parse(rest, datetime, format_options, [result | acc])
  end

  # Hour using a 24-hour clock
  defp format_modifiers("H" <> rest, width, pad, datetime, format_options, acc) do
    result = datetime.hour |> to_string() |> String.pad_leading(width, pad)
    parse(rest, datetime, format_options, [result | acc])
  end

  # Hour using a 12-hour clock
  defp format_modifiers("I" <> rest, width, pad, datetime, format_options, acc) do
    result = (rem(datetime.hour() + 23, 12) + 1) |> to_string() |> String.pad_leading(width, pad)
    parse(rest, datetime, format_options, [result | acc])
  end

  # Day of the year
  defp format_modifiers("j" <> rest, width, pad, datetime, format_options, acc) do
    result = datetime |> Date.day_of_year() |> to_string() |> String.pad_leading(width, pad)
    parse(rest, datetime, format_options, [result | acc])
  end

  # Month
  defp format_modifiers("m" <> rest, width, pad, datetime, format_options, acc) do
    result = datetime.month |> to_string() |> String.pad_leading(width, pad)
    parse(rest, datetime, format_options, [result | acc])
  end

  # Minute
  defp format_modifiers("M" <> rest, width, pad, datetime, format_options, acc) do
    result = datetime.minute |> to_string() |> String.pad_leading(width, pad)
    parse(rest, datetime, format_options, [result | acc])
  end

  # “AM” or “PM” (noon is “PM”, midnight as “AM”)
  defp format_modifiers("p" <> rest, width, pad, datetime, format_options, acc) do
    result =
      datetime.hour |> am_pm(format_options) |> String.upcase() |> String.pad_leading(width, pad)

    parse(rest, datetime, format_options, [result | acc])
  end

  # “am” or “pm” (noon is “pm”, midnight as “am”)
  defp format_modifiers("P" <> rest, width, pad, datetime, format_options, acc) do
    result =
      datetime.hour
      |> am_pm(format_options)
      |> String.downcase()
      |> String.pad_leading(width, pad)

    parse(rest, datetime, format_options, [result | acc])
  end

  # Quarter
  defp format_modifiers("q" <> rest, width, pad, datetime, format_options, acc) do
    result = datetime |> Date.quarter_of_year() |> to_string() |> String.pad_leading(width, pad)
    parse(rest, datetime, format_options, [result | acc])
  end

  # Second
  defp format_modifiers("S" <> rest, width, pad, datetime, format_options, acc) do
    result = datetime.second |> to_string() |> String.pad_leading(width, pad)
    parse(rest, datetime, format_options, [result | acc])
  end

  # Day of the week
  defp format_modifiers("u" <> rest, width, pad, datetime, format_options, acc) do
    result = datetime |> Date.day_of_week() |> to_string() |> String.pad_leading(width, pad)
    parse(rest, datetime, format_options, [result | acc])
  end

  # Preferred date (without time) representation
  defp format_modifiers(
         "x" <> _rest,
         _width,
         _pad,
         _datetime,
         %{preferred_date_invoked: true},
         _acc
       ) do
    raise RuntimeError,
          "tried to format preferred_date within another preferred_date format"
  end

  defp format_modifiers("x" <> rest, width, pad, datetime, format_options, acc) do
    result =
      format_options.preferred_date
      |> parse(datetime, %{format_options | preferred_date_invoked: true})
      |> pad_preferred(width, pad)

    parse(rest, datetime, format_options, [result | acc])
  end

  # Preferred time (without date) representation
  defp format_modifiers(
         "X" <> _rest,
         _width,
         _pad,
         _datetime,
         %{preferred_time_invoked: true},
         _acc
       ) do
    raise RuntimeError,
          "tried to format preferred_time within another preferred_time format"
  end

  defp format_modifiers("X" <> rest, width, pad, datetime, format_options, acc) do
    result =
      format_options.preferred_time
      |> parse(datetime, %{format_options | preferred_time_invoked: true})
      |> pad_preferred(width, pad)

    parse(rest, datetime, format_options, [result | acc])
  end

  # Year as 2-digits
  defp format_modifiers("y" <> rest, width, pad, datetime, format_options, acc) do
    result = datetime.year |> rem(100) |> to_string() |> String.pad_leading(width, pad)
    parse(rest, datetime, format_options, [result | acc])
  end

  # Year
  defp format_modifiers("Y" <> rest, width, pad, datetime, format_options, acc) do
    result = datetime.year |> to_string() |> String.pad_leading(width, pad)
    parse(rest, datetime, format_options, [result | acc])
  end

  # +hhmm/-hhmm time zone offset from UTC (empty string if naive)
  defp format_modifiers(
         "z" <> rest,
         width,
         pad,
         datetime = %{utc_offset: utc_offset, std_offset: std_offset},
         format_options,
         acc
       ) do
    absolute_offset = abs(utc_offset + std_offset)

    offset_number =
      to_string(div(absolute_offset, 3600) * 100 + rem(div(absolute_offset, 60), 60))

    sign = if datetime.utc_offset + datetime.std_offset >= 0, do: "+", else: "-"
    result = "#{sign}#{String.pad_leading(offset_number, width, pad)}"
    parse(rest, datetime, format_options, [result | acc])
  end

  defp format_modifiers("z" <> rest, _width, _pad, datetime, format_options, acc) do
    parse(rest, datetime, format_options, ["" | acc])
  end

  # Time zone abbreviation (empty string if naive)
  defp format_modifiers("Z" <> rest, width, pad, datetime, format_options, acc) do
    result = datetime |> Map.get(:zone_abbr, "") |> String.pad_leading(width, pad)
    parse(rest, datetime, format_options, [result | acc])
  end

  defp pad_preferred(result, width, pad) when length(result) < width do
    pad_preferred([pad | result], width, pad)
  end

  defp pad_preferred(result, _width, _pad), do: result

  defp options(user_options) do
    Enum.reduce(user_options, @default_options, fn {key, value}, acc ->
      if Map.has_key?(acc, key) do
        %{acc | key => value}
      else
        acc
      end
    end)
  end
end
