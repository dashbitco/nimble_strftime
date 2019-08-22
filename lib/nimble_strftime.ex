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
  alias NimbleStrftime.FormatOptions

  @doc """
    Formats received datetime into a String
  """
  @spec format(
          Date.t() | Time.t() | NaiveDateTime.t() | DateTime.t(),
          String.t(),
          FormatOptions.options()
        ) :: String.t()
  def format(date_or_time_or_datetime, string_format, format_options \\ []) do
    parse(
      string_format,
      date_or_time_or_datetime,
      Map.merge(%FormatOptions{}, Map.new(format_options))
    )
  end

  defp parse(data, datetime, format_options, acc \\ [])

  defp parse("", _datetime, _format_options, acc),
    do: acc |> Enum.reverse() |> IO.iodata_to_binary()

  defp parse("%" <> rest, datetime, format_options, acc),
    do: parse_stream(rest, nil, nil, [datetime, format_options, acc])

  defp parse(<<char::binary-1, rest::binary>>, datetime, format_options, acc) do
    parse(rest, datetime, format_options, [char | acc])
  end

  @spec parse_stream(
          String.t(),
          integer() | nil,
          String.t() | nil,
          list()
        ) :: String.t()
  defp parse_stream("-" <> rest, width, nil, parser_data) do
    parse_stream(rest, width, "-", parser_data)
  end

  defp parse_stream("0" <> rest, width, nil, parser_data) do
    parse_stream(rest, width, "0", parser_data)
  end

  defp parse_stream("_" <> rest, width, nil, parser_data) do
    parse_stream(
      rest,
      width,
      " ",
      parser_data
    )
  end

  defp parse_stream(<<digit, rest::binary>>, width, pad, parser_data)
       when digit in ?0..?9 do
    new_width =
      case pad do
        "-" -> 0
        _ -> (width || 0) * 10 + (digit - ?0)
      end

    parse_stream(rest, new_width, pad, parser_data)
  end

  defp parse_stream(rest, width, pad, [datetime, format_options, acc]) do
    convert_stream(rest, width, pad, datetime, format_options, acc)
  end

  defp am_pm(hour, format_options) when hour > 11 do
    FormatOptions.pm_name(format_options)
  end

  defp am_pm(hour, format_options) when hour <= 11 do
    FormatOptions.am_name(format_options)
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
  defp convert_stream(
         stream = <<format::binary-1, _rest::binary>>,
         width,
         nil,
         datetime,
         format_options,
         acc
       ) do
    convert_stream(stream, width, default_pad(format), datetime, format_options, acc)
  end

  # set default width if none was specified
  defp convert_stream(
         stream = <<format::binary-1, _rest::binary>>,
         nil,
         pad,
         datetime,
         format_options,
         acc
       ) do
    convert_stream(stream, default_width(format), pad, datetime, format_options, acc)
  end

  # Literally just %
  defp convert_stream("%" <> rest, width, pad, datetime, format_options, acc) do
    parse(rest, datetime, format_options, [String.pad_leading("%", width, pad) | acc])
  end

  # Abbreviated name of day
  defp convert_stream("a" <> rest, width, pad, datetime, format_options, acc) do
    result =
      datetime
      |> Date.day_of_week()
      |> FormatOptions.day_of_week_name_abbreviated(format_options)
      |> String.pad_leading(width, pad)

    parse(rest, datetime, format_options, [result | acc])
  end

  # Full name of day
  defp convert_stream("A" <> rest, width, pad, datetime, format_options, acc) do
    result =
      datetime
      |> Date.day_of_week()
      |> FormatOptions.day_of_week_name(format_options)
      |> String.pad_leading(width, pad)

    parse(rest, datetime, format_options, [result | acc])
  end

  # Abbreviated month name
  defp convert_stream("b" <> rest, width, pad, datetime, format_options, acc) do
    result =
      datetime.month
      |> FormatOptions.month_name_abbreviated(format_options)
      |> String.pad_leading(width, pad)

    parse(rest, datetime, format_options, [result | acc])
  end

  # Full month name
  defp convert_stream("B" <> rest, width, pad, datetime, format_options, acc) do
    result =
      datetime.month |> FormatOptions.month_name(format_options) |> String.pad_leading(width, pad)

    parse(rest, datetime, format_options, [result | acc])
  end

  # Preferred date+time representation
  defp convert_stream(
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

  defp convert_stream("c" <> rest, width, pad, datetime, format_options, acc) do
    result =
      format_options.preferred_datetime
      |> parse(datetime, %{format_options | preferred_datetime_invoked: true})
      |> String.pad_leading(width, pad)

    parse(rest, datetime, %{format_options | preferred_datetime_invoked: false}, [result | acc])
  end

  # Day of the month
  defp convert_stream("d" <> rest, width, pad, datetime, format_options, acc) do
    result = datetime.day |> to_string() |> String.pad_leading(width, pad)
    parse(rest, datetime, format_options, [result | acc])
  end

  # Microseconds
  defp convert_stream("f" <> rest, width, pad, datetime, format_options, acc) do
    result = datetime.microsecond |> elem(0) |> to_string() |> String.pad_leading(width, pad)
    parse(rest, datetime, format_options, [result | acc])
  end

  # Hour using a 24-hour clock
  defp convert_stream("H" <> rest, width, pad, datetime, format_options, acc) do
    result = datetime.hour |> to_string() |> String.pad_leading(width, pad)
    parse(rest, datetime, format_options, [result | acc])
  end

  # Hour using a 12-hour clock
  defp convert_stream("I" <> rest, width, pad, datetime, format_options, acc) do
    result = (rem(datetime.hour() + 23, 12) + 1) |> to_string() |> String.pad_leading(width, pad)
    parse(rest, datetime, format_options, [result | acc])
  end

  # Day of the year
  defp convert_stream("j" <> rest, width, pad, datetime, format_options, acc) do
    result = datetime |> Date.day_of_year() |> to_string() |> String.pad_leading(width, pad)
    parse(rest, datetime, format_options, [result | acc])
  end

  # Month
  defp convert_stream("m" <> rest, width, pad, datetime, format_options, acc) do
    result = datetime.month |> to_string() |> String.pad_leading(width, pad)
    parse(rest, datetime, format_options, [result | acc])
  end

  # Minute
  defp convert_stream("M" <> rest, width, pad, datetime, format_options, acc) do
    result = datetime.minute |> to_string() |> String.pad_leading(width, pad)
    parse(rest, datetime, format_options, [result | acc])
  end

  # “AM” or “PM” (noon is “PM”, midnight as “AM”)
  defp convert_stream("p" <> rest, width, pad, datetime, format_options, acc) do
    result =
      datetime.hour |> am_pm(format_options) |> String.upcase() |> String.pad_leading(width, pad)

    parse(rest, datetime, format_options, [result | acc])
  end

  # “am” or “pm” (noon is “pm”, midnight as “am”)
  defp convert_stream("P" <> rest, width, pad, datetime, format_options, acc) do
    result =
      datetime.hour
      |> am_pm(format_options)
      |> String.downcase()
      |> String.pad_leading(width, pad)

    parse(rest, datetime, format_options, [result | acc])
  end

  # Quarter
  defp convert_stream("q" <> rest, width, pad, datetime, format_options, acc) do
    result = datetime |> Date.quarter_of_year() |> to_string() |> String.pad_leading(width, pad)
    parse(rest, datetime, format_options, [result | acc])
  end

  # Second
  defp convert_stream("S" <> rest, width, pad, datetime, format_options, acc) do
    result = datetime.second |> to_string() |> String.pad_leading(width, pad)
    parse(rest, datetime, format_options, [result | acc])
  end

  # Day of the week
  defp convert_stream("u" <> rest, width, pad, datetime, format_options, acc) do
    result = datetime |> Date.day_of_week() |> to_string() |> String.pad_leading(width, pad)
    parse(rest, datetime, format_options, [result | acc])
  end

  # Preferred date (without time) representation
  defp convert_stream(
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

  defp convert_stream("x" <> rest, width, pad, datetime, format_options, acc) do
    result =
      format_options.preferred_date
      |> parse(datetime, %{format_options | preferred_date_invoked: true})
      |> String.pad_leading(width, pad)

    parse(rest, datetime, %{format_options | preferred_date_invoked: false}, [result | acc])
  end

  # Preferred time (without date) representation
  defp convert_stream(
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

  defp convert_stream("X" <> rest, width, pad, datetime, format_options, acc) do
    result =
      format_options.preferred_time
      |> parse(datetime, %{format_options | preferred_time_invoked: true})
      |> String.pad_leading(width, pad)

    parse(rest, datetime, %{format_options | preferred_time_invoked: false}, [result | acc])
  end

  # Year as 2-digits
  defp convert_stream("y" <> rest, width, pad, datetime, format_options, acc) do
    result = datetime.year |> rem(100) |> to_string() |> String.pad_leading(width, pad)
    parse(rest, datetime, format_options, [result | acc])
  end

  # Year
  defp convert_stream("Y" <> rest, width, pad, datetime, format_options, acc) do
    result = datetime.year |> to_string() |> String.pad_leading(width, pad)
    parse(rest, datetime, format_options, [result | acc])
  end

  # +hhmm/-hhmm time zone offset from UTC (empty string if naive)
  defp convert_stream(
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

  defp convert_stream("z" <> rest, _width, _pad, datetime, format_options, acc) do
    parse(rest, datetime, format_options, ["" | acc])
  end

  # Time zone abbreviation (empty string if naive)
  defp convert_stream("Z" <> rest, width, pad, datetime, format_options, acc) do
    result = datetime |> Map.get(:zone_abbr, "") |> String.pad_leading(width, pad)
    parse(rest, datetime, format_options, [result | acc])
  end
end
