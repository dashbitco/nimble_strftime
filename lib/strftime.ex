defmodule Strftime do
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
  * `J` -  Day of the year
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
  alias Strftime.FormatStream
  alias Strftime.FormatOptions

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
    do: parse_stream(rest, %FormatStream{}, [datetime, format_options, acc])

  defp parse(<<char::binary-1, rest::binary>>, datetime, format_options, acc) do
    parse(rest, datetime, format_options, [char | acc])
  end

  @spec parse_stream(
          String.t(),
          FormatStream.t(),
          list()
        ) :: {FormatStream.t(), String.t()}
  defp parse_stream("", format_stream, [datetime, format_options, acc]) do
    apply_stream(
      format_stream,
      datetime,
      format_options,
      "",
      acc
    )
  end

  defp parse_stream("-" <> rest, format_stream = %{pad: nil}, parser_data) do
    parse_stream(
      rest,
      %{format_stream | pad: "-", section: ["-" | format_stream.section]},
      parser_data
    )
  end

  defp parse_stream("0" <> rest, format_stream = %{pad: nil}, parser_data) do
    parse_stream(
      rest,
      %{format_stream | pad: "0", section: ["0" | format_stream.section]},
      parser_data
    )
  end

  defp parse_stream("_" <> rest, format_stream = %{pad: nil}, parser_data) do
    parse_stream(
      rest,
      %{format_stream | pad: " ", section: ["_" | format_stream.section]},
      parser_data
    )
  end

  defp parse_stream(<<digit::utf8, rest::binary>>, format_stream = %{pad: pad}, parser_data)
       when digit > 47 and digit < 58 do
    new_width =
      case pad do
        "-" -> 0
        _ -> (format_stream.width || 0) * 10 + (digit - 48)
      end

    parse_stream(
      rest,
      %{format_stream | width: new_width, section: [<<digit>> | format_stream.section]},
      parser_data
    )
  end

  defp parse_stream(<<format::binary-1, rest::binary>>, format_stream, [
         datetime,
         format_options,
         acc
       ]) do
    apply_stream(
      %{format_stream | format: format, section: [format | format_stream.section]},
      datetime,
      format_options,
      rest,
      acc
    )
  end

  defp apply_stream(%{format: format}, %Date{}, _format_options, _rest, _acc)
       when format in ~w(c f H I M p P S X) do
    raise "format `%#{format}` is not compatible with `Date` structs, please try using a `DateTime` or a `Time`"
  end

  defp apply_stream(%{format: format}, %Time{}, _format_options, _rest, _acc)
       when format in ~w(a A b B c d J m q u x y Y) do
    raise "format `%#{format}` is not compatible with `Time` structs, please try using a `DateTime` or a `Date`"
  end

  defp apply_stream(
         format_stream = %{format: format, pad: nil},
         datetime,
         format_options,
         rest,
         acc
       ) do
    apply_stream(%{format_stream | pad: default_pad(format)}, datetime, format_options, rest, acc)
  end

  defp apply_stream(
         format_stream = %{format: format, width: nil},
         datetime,
         format_options,
         rest,
         acc
       ) do
    apply_stream(
      %{format_stream | width: default_width(format)},
      datetime,
      format_options,
      rest,
      acc
    )
  end

  defp apply_stream(
         format_stream = %FormatStream{format: format, width: width, pad: pad},
         datetime,
         format_options,
         rest,
         acc
       ) do
    formatted_result =
      case format do
        # Literal `%`
        "%" ->
          "%"

        # Abbreviated name of day
        "a" ->
          datetime
          |> Date.day_of_week()
          |> FormatOptions.day_of_week_name_abbreviated(format_options)

        # Full name of day
        "A" ->
          datetime
          |> Date.day_of_week()
          |> FormatOptions.day_of_week_name(format_options)

        # Abbreviated month name
        "b" ->
          FormatOptions.month_name_abbreviated(datetime.month(), format_options)

        # Full month name
        "B" ->
          FormatOptions.month_name(datetime.month(), format_options)

        # Preferred date+time representation
        "c" ->
          parse(format_options.preferred_datetime, datetime, format_options)

        # Day of the month
        "d" ->
          datetime.day()

        # Microseconds
        "f" ->
          elem(datetime.microsecond(), 0)

        # Hour using a 24-hour clock
        "H" ->
          datetime.hour()

        # Hour using a 12-hour clock
        "I" ->
          rem(datetime.hour() + 23, 12) + 1

        # Day of the year
        "j" ->
          Date.day_of_year(datetime)

        # Month
        "m" ->
          datetime.month()

        # Minute
        "M" ->
          datetime.minute()

        # “AM” or “PM” (noon is “PM”, midnight as “AM”)
        "p" ->
          datetime.hour()
          |> am_pm(format_options)
          |> String.upcase()

        # “am” or “pm” (noon is “pm”, midnight as “am”)
        "P" ->
          datetime.hour()
          |> am_pm(format_options)
          |> String.downcase()

        # Quarter
        "q" ->
          Date.quarter_of_year(datetime)

        # Second
        "S" ->
          datetime.second()

        # Day of the week
        "u" ->
          Date.day_of_week(datetime)

        # Preferred date (without time) representation
        "x" ->
          parse(format_options.preferred_date, datetime, format_options)

        # Preferred time (without date) representation
        "X" ->
          parse(format_options.preferred_time, datetime, format_options)

        # Year as 2-digits
        "y" ->
          rem(datetime.year(), 100)

        # Year
        "Y" ->
          datetime.year()

        # +hhmm/-hhmm time zone offset from UTC (empty string if naive)
        "z" ->
          case datetime do
            %DateTime{} -> time_offset(datetime.utc_offset + datetime.std_offset)
            _ -> ""
          end

        # Time zone abbreviation (empty string if naive)
        "Z" ->
          Map.get(datetime, :zone_abbr, "")

        _ ->
          format_stream.section |> Enum.reverse() |> IO.iodata_to_binary()
      end
      |> to_string()
      |> String.pad_leading(width, pad)

    parse(rest, datetime, format_options, [formatted_result | acc])
  end

  defp am_pm(hour, format_options) when hour > 11 do
    FormatOptions.pm_name(format_options)
  end

  defp am_pm(hour, format_options) when hour < 11 do
    FormatOptions.am_name(format_options)
  end

  defp time_offset(offset_in_seconds) do
    absolute_offset = abs(offset_in_seconds)
    offset_number = to_string(div(offset_in_seconds, 3600) * 100 + rem(div(offset_in_seconds, 60), 60))
    sign = if offset_in_seconds >= 0, do: "+", else: "-"
    "#{sign}#{String.pad_leading(offset_number, 4, "0")}"
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
      "Y" -> 4
      _ -> 0
    end
  end
end
