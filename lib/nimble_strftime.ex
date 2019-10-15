defmodule NimbleStrftime do
  @moduledoc """
  Simple datetime formatting based on the strftime format
  found on UNIX-like systems.

  ## Formatting syntax

  The formatting syntax for strftime is a sequence of characters in the following format:

      %<padding><width><format>

  where:

    * `%`: indicates the start of a formatted section
    * `<padding>`: set the padding (see below)
    * `<width>`: a number indicating the minimum size of the formatted section
    * `<format>`: the format iself (see below)

  ### Accepted padding options

    * `-`: no padding, removes all padding from the format
    * `_`: pad with spaces
    * `0`: pad with zeroes

  ### Accepted formats

  The accepted formats are:

  Format | Description                                                             | Examples (in ISO)
  :----- | :-----------------------------------------------------------------------| :------------------------
  a      | Abbreviated name of day                                                 | Mon
  A      | Full name of day                                                        | Monday
  b      | Abbreviated month name                                                  | Jan
  B      | Full month name                                                         | January
  c      | Preferred date+time representation                                      | 2018-10-17 12:34:56
  d      | Day of the month                                                        | 01, 12
  f      | Microseconds *(does not support width and padding modifiers)*           | 000000, 999999, 0123
  H      | Hour using a 24-hour clock                                              | 00, 23
  I      | Hour using a 12-hour clock                                              | 01, 12
  j      | Day of the year                                                         | 001, 366
  m      | Month                                                                   | 01, 12
  M      | Minute                                                                  | 00, 59
  p      | "AM" or "PM" (noon is "PM", midnight as "AM")                           | AM, PM
  P      | "am" or "pm" (noon is "pm", midnight as "am")                           | am, pm
  q      | Quarter                                                                 | 1, 2, 3, 4
  S      | Second                                                                  | 00, 59, 60
  u      | Day of the week                                                         | 1 (Monday), 7 (Sunday)
  x      | Preferred date (without time) representation                            | 2018-10-17
  X      | Preferred time (without date) representation                            | 12:34:56
  y      | Year as 2-digits                                                        | 01, 01, 86, 18
  Y      | Year                                                                    | -0001, 0001, 1986
  z      | +hhmm/-hhmm time zone offset from UTC (empty string if naive)           | +0300, -0530
  Z      | Time zone abbreviation (empty string if naive)                          | CET, BRST
  %      | Literal "%" character                                                   | %

  Any other character will be interpreted as an invalid format and raise an error
  """

  @doc """
  Formats received datetime into a string.

  The datetime can be any of the Calendar types (`Time`, `Date`,
  `NaiveDateTime`, and `DateTime`) or any map, as long as they
  contain all of the relevant fields necessary for formatting.
  For example, if you use `%Y` to format the year, the datatime
  must have the `:year` field. Therefore, if you pass a `Time`,
  or a map without the `:year` field to a format that expects `%Y`,
  an error will be raised.

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

    * `:am_pm_names` - a function that receives either `:am` or `:pm` and returns
      the name of the period of the day, if the option is not received it defaults
      to a function that returns `"am"` and `"pm"`, respectively

    *  `:month_names` - a function that receives a number and returns the name of
      the corresponding month, if the option is not received it defaults to a
      function thet returns the month names in english

    * `:abbreviated_month_names` - a function that receives a number and returns the
      abbreviated name of the corresponding month, if the option is not received it
      defaults to a function thet returns the abbreviated month names in english

    * `:day_of_week_names` - a function that receives a number and returns the name of
      the corresponding day of week, if the option is not received it defaults to a
      function that returns the day of week names in english

    * `:abbreviated_day_of_week_names` - a function that receives a number and returns
      the abbreviated name of the corresponding day of week, if the option is not received 
      it defaults to a function that returns the abbreviated day of week names in english

  ## Examples

  Without options:

      iex> NimbleStrftime.format(~U[2019-08-26 13:52:06.0Z], "%y-%m-%d %I:%M:%S %p")
      "19-08-26 01:52:06 PM"

      iex> NimbleStrftime.format(~U[2019-08-26 13:52:06.0Z], "%a, %B %d %Y")
      "Mon, August 26 2019"

      iex> NimbleStrftime.format(~U[2019-08-26 13:52:06.0Z], "%c")
      "2019-08-26 13:52:06"

  With options:

      iex> NimbleStrftime.format(~U[2019-08-26 13:52:06.0Z], "%c", preferred_datetime: "%H:%M:%S %d-%m-%y")
      "13:52:06 26-08-19"

      iex> NimbleStrftime.format(
      ...>  ~U[2019-08-26 13:52:06.0Z],
      ...>  "%A",
      ...>  day_of_week_names: fn day_of_week ->
      ...>    {"segunda-feira", "terça-feira", "quarta-feira", "quinta-feira",
      ...>    "sexta-feira", "sábado", "domingo"}
      ...>    |> elem(day_of_week - 1)
      ...>  end
      ...>)
      "segunda-feira"

      iex> NimbleStrftime.format(
      ...>  ~U[2019-08-26 13:52:06.0Z],
      ...>  "%B",
      ...>  month_names: fn month ->
      ...>    {"январь", "февраль", "март", "апрель", "май", "июнь",
      ...>    "июль", "август", "сентябрь", "октябрь", "ноябрь", "декабрь"}
      ...>    |> elem(month - 1)
      ...>  end
      ...>)
      "август"
  """
  @spec format(map(), String.t(), keyword()) :: String.t()
  def format(date_or_time_or_datetime, string_format, user_options \\ []) do
    parse(
      string_format,
      date_or_time_or_datetime,
      options(user_options),
      []
    )
    |> IO.iodata_to_binary()
  end

  defp parse("", _datetime, _format_options, acc),
    do: Enum.reverse(acc)

  defp parse("%" <> rest, datetime, format_options, acc),
    do: parse_modifiers(rest, nil, nil, {datetime, format_options, acc})

  defp parse(<<char::binary-1, rest::binary>>, datetime, format_options, acc),
    do: parse(rest, datetime, format_options, [char | acc])

  defp parse_modifiers("-" <> rest, width, nil, parser_data) do
    parse_modifiers(rest, width, "", parser_data)
  end

  defp parse_modifiers("0" <> rest, width, nil, parser_data) do
    parse_modifiers(rest, width, ?0, parser_data)
  end

  defp parse_modifiers("_" <> rest, width, nil, parser_data) do
    parse_modifiers(rest, width, ?\s, parser_data)
  end

  defp parse_modifiers(<<digit, rest::binary>>, width, pad, parser_data) when digit in ?0..?9 do
    new_width =
      case pad do
        ?- -> 0
        _ -> (width || 0) * 10 + (digit - ?0)
      end

    parse_modifiers(rest, new_width, pad, parser_data)
  end

  # set default padding if none was specfied
  defp parse_modifiers(<<format, _::binary>> = rest, width, nil, parser_data) do
    parse_modifiers(rest, width, default_pad(format), parser_data)
  end

  # set default width if none was specified
  defp parse_modifiers(<<format, _::binary>> = rest, nil, pad, parser_data) do
    parse_modifiers(rest, default_width(format), pad, parser_data)
  end

  defp parse_modifiers(rest, width, pad, {datetime, format_options, acc}) do
    format_modifiers(rest, width, pad, datetime, format_options, acc)
  end

  defp am_pm(hour, format_options) when hour > 11 do
    format_options.am_pm_names.(:pm)
  end

  defp am_pm(hour, format_options) when hour <= 11 do
    format_options.am_pm_names.(:am)
  end

  defp default_pad(format) when format in 'aAbBpPZ', do: ?\s
  defp default_pad(_format), do: ?0

  defp default_width(format) when format in 'dHImMSy', do: 2
  defp default_width(?j), do: 3
  defp default_width(format) when format in 'Yz', do: 4
  defp default_width(_format), do: 0

  # Literally just %
  defp format_modifiers("%" <> rest, width, pad, datetime, format_options, acc) do
    parse(rest, datetime, format_options, [pad_leading("%", width, pad) | acc])
  end

  # Abbreviated name of day
  defp format_modifiers("a" <> rest, width, pad, datetime, format_options, acc) do
    result =
      datetime
      |> Date.day_of_week()
      |> format_options.abbreviated_day_of_week_names.()
      |> pad_leading(width, pad)

    parse(rest, datetime, format_options, [result | acc])
  end

  # Full name of day
  defp format_modifiers("A" <> rest, width, pad, datetime, format_options, acc) do
    result =
      datetime
      |> Date.day_of_week()
      |> format_options.day_of_week_names.()
      |> pad_leading(width, pad)

    parse(rest, datetime, format_options, [result | acc])
  end

  # Abbreviated month name
  defp format_modifiers("b" <> rest, width, pad, datetime, format_options, acc) do
    result =
      datetime.month
      |> format_options.abbreviated_month_names.()
      |> pad_leading(width, pad)

    parse(rest, datetime, format_options, [result | acc])
  end

  # Full month name
  defp format_modifiers("B" <> rest, width, pad, datetime, format_options, acc) do
    result = datetime.month |> format_options.month_names.() |> pad_leading(width, pad)

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
      |> parse(datetime, %{format_options | preferred_datetime_invoked: true}, [])
      |> pad_preferred(width, pad)

    parse(rest, datetime, format_options, [result | acc])
  end

  # Day of the month
  defp format_modifiers("d" <> rest, width, pad, datetime, format_options, acc) do
    result = datetime.day |> Integer.to_string() |> pad_leading(width, pad)
    parse(rest, datetime, format_options, [result | acc])
  end

  # Microseconds
  defp format_modifiers("f" <> rest, _width, _pad, datetime, format_options, acc) do
    {microsecond, precision} = datetime.microsecond

    result =
      microsecond
      |> Integer.to_string()
      |> String.pad_leading(6, "0")
      |> binary_part(0, max(precision, 1))

    parse(rest, datetime, format_options, [result | acc])
  end

  # Hour using a 24-hour clock
  defp format_modifiers("H" <> rest, width, pad, datetime, format_options, acc) do
    result = datetime.hour |> Integer.to_string() |> pad_leading(width, pad)
    parse(rest, datetime, format_options, [result | acc])
  end

  # Hour using a 12-hour clock
  defp format_modifiers("I" <> rest, width, pad, datetime, format_options, acc) do
    result = (rem(datetime.hour() + 23, 12) + 1) |> Integer.to_string() |> pad_leading(width, pad)
    parse(rest, datetime, format_options, [result | acc])
  end

  # Day of the year
  defp format_modifiers("j" <> rest, width, pad, datetime, format_options, acc) do
    result = datetime |> Date.day_of_year() |> Integer.to_string() |> pad_leading(width, pad)
    parse(rest, datetime, format_options, [result | acc])
  end

  # Month
  defp format_modifiers("m" <> rest, width, pad, datetime, format_options, acc) do
    result = datetime.month |> Integer.to_string() |> pad_leading(width, pad)
    parse(rest, datetime, format_options, [result | acc])
  end

  # Minute
  defp format_modifiers("M" <> rest, width, pad, datetime, format_options, acc) do
    result = datetime.minute |> Integer.to_string() |> pad_leading(width, pad)
    parse(rest, datetime, format_options, [result | acc])
  end

  # “AM” or “PM” (noon is “PM”, midnight as “AM”)
  defp format_modifiers("p" <> rest, width, pad, datetime, format_options, acc) do
    result = datetime.hour |> am_pm(format_options) |> String.upcase() |> pad_leading(width, pad)

    parse(rest, datetime, format_options, [result | acc])
  end

  # “am” or “pm” (noon is “pm”, midnight as “am”)
  defp format_modifiers("P" <> rest, width, pad, datetime, format_options, acc) do
    result =
      datetime.hour
      |> am_pm(format_options)
      |> String.downcase()
      |> pad_leading(width, pad)

    parse(rest, datetime, format_options, [result | acc])
  end

  # Quarter
  defp format_modifiers("q" <> rest, width, pad, datetime, format_options, acc) do
    result = datetime |> Date.quarter_of_year() |> Integer.to_string() |> pad_leading(width, pad)
    parse(rest, datetime, format_options, [result | acc])
  end

  # Second
  defp format_modifiers("S" <> rest, width, pad, datetime, format_options, acc) do
    result = datetime.second |> Integer.to_string() |> pad_leading(width, pad)
    parse(rest, datetime, format_options, [result | acc])
  end

  # Day of the week
  defp format_modifiers("u" <> rest, width, pad, datetime, format_options, acc) do
    result = datetime |> Date.day_of_week() |> Integer.to_string() |> pad_leading(width, pad)
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
      |> parse(datetime, %{format_options | preferred_date_invoked: true}, [])
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
      |> parse(datetime, %{format_options | preferred_time_invoked: true}, [])
      |> pad_preferred(width, pad)

    parse(rest, datetime, format_options, [result | acc])
  end

  # Year as 2-digits
  defp format_modifiers("y" <> rest, width, pad, datetime, format_options, acc) do
    result = datetime.year |> rem(100) |> Integer.to_string() |> pad_leading(width, pad)
    parse(rest, datetime, format_options, [result | acc])
  end

  # Year
  defp format_modifiers("Y" <> rest, width, pad, datetime, format_options, acc) do
    result = datetime.year |> Integer.to_string() |> pad_leading(width, pad)
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
      Integer.to_string(div(absolute_offset, 3600) * 100 + rem(div(absolute_offset, 60), 60))

    sign = if utc_offset + std_offset >= 0, do: "+", else: "-"
    result = "#{sign}#{pad_leading(offset_number, width, pad)}"
    parse(rest, datetime, format_options, [result | acc])
  end

  defp format_modifiers("z" <> rest, _width, _pad, datetime, format_options, acc) do
    parse(rest, datetime, format_options, ["" | acc])
  end

  # Time zone abbreviation (empty string if naive)
  defp format_modifiers("Z" <> rest, width, pad, datetime, format_options, acc) do
    result = datetime |> Map.get(:zone_abbr, "") |> pad_leading(width, pad)
    parse(rest, datetime, format_options, [result | acc])
  end

  defp pad_preferred(result, width, pad) when length(result) < width do
    pad_preferred([pad | result], width, pad)
  end

  defp pad_preferred(result, _width, _pad), do: result

  defp pad_leading(string, count, padding) do
    to_pad = count - byte_size(string)
    if to_pad > 0, do: do_pad_leading(to_pad, padding, string), else: string
  end

  defp do_pad_leading(0, _, acc), do: acc

  defp do_pad_leading(count, padding, acc),
    do: do_pad_leading(count - 1, padding, [padding | acc])

  defp options(user_options) do
    default_options = %{
      preferred_date: "%Y-%m-%d",
      preferred_time: "%H:%M:%S",
      preferred_datetime: "%Y-%m-%d %H:%M:%S",
      am_pm_names: fn
        :am -> "am"
        :pm -> "pm"
      end,
      month_names: fn month ->
        {"January", "February", "March", "April", "May", "June", "July", "August", "September",
         "October", "November", "December"}
        |> elem(month - 1)
      end,
      day_of_week_names: fn day_of_week ->
        {"Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"}
        |> elem(day_of_week - 1)
      end,
      abbreviated_month_names: fn month ->
        {"Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"}
        |> elem(month - 1)
      end,
      abbreviated_day_of_week_names: fn day_of_week ->
        {"Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"} |> elem(day_of_week - 1)
      end,
      preferred_datetime_invoked: false,
      preferred_date_invoked: false,
      preferred_time_invoked: false
    }

    Enum.reduce(user_options, default_options, fn {key, value}, acc ->
      if Map.has_key?(acc, key) do
        %{acc | key => value}
      else
        acc
      end
    end)
  end
end
