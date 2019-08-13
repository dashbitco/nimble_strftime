defmodule Strftime do
  @moduledoc """
  Documentation for Strftime.
  """

  @empty_date %{
    day: 1,
    hour: 0,
    microsecond: {0, 0},
    minute: 0,
    month: 1,
    second: 0,
    year: 0,
    std_offset: 0,
    time_zone: "",
    utc_offset: 0,
    zone_abbr: ""
  }

  @spec format(Date.t() | Time.t() | DateTime.t(), String.t()) :: String.t()
  def format(date_or_time_or_datetime, string_format) do
    Regex.scan(
      ~r/(?<all_match>%(?<padding>(_|-|0)*)(?<length>\d*)(?<format>\w|%))/,
      string_format,
      capture: :all_names
    )
    |> Enum.reduce(string_format, &format_chunk(date_or_time_or_datetime, &1, &2))
  end

  defp format_chunk(date_or_time_or_datetime, [all_match, format, length, padding], string_format) do
    padding_length = padding_length(length, format, padding)
    padding_type = padding_type(padding, format)

    formatted_chunk =
      case format do
        # Literal “%” character
        "%" ->
          "%"

        # format code
        format ->
          @empty_date
          |> Map.merge(date_or_time_or_datetime)
          |> format(format, padding_length, padding_type)
      end

    String.replace(string_format, all_match, formatted_chunk)
  end

  defp padding_length(_length, _format, "-"), do: 0

  defp padding_length("", format, _padding) do
    case format do
      format when format in ~w(d H I m M S u y) -> 2
      "j" -> 3
      "Y" -> 4
      _ -> 0
    end
  end

  defp padding_length(length, _format, _padding), do: String.to_integer(length)

  defp padding_type("0", _format), do: "0"
  defp padding_type(padding, format) when padding == "_" or format in ~w(a A b B p P Z), do: " "
  defp padding_type("", _format), do: "0"
  defp padding_type("-", _format), do: "-"

  defp format(datetime, format, padding_length, padding_type) do
    case format do
      # Abbreviated name of day
      "a" ->
        "TBD"

      # Full name of day
      "A" ->
        "TBD"

      # Abbreviated month name
      "b" ->
        "TBD"

      # Full month name
      "B" ->
        "TBD"

      # Preferred date+time representation
      "c" ->
        "TBD"

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
        datetime.__struct__.day_of_year(datetime)

      # Month
      "m" ->
        datetime.month()

      # Minute
      "M" ->
        datetime.minute()

      # “AM” or “PM” (noon is “PM”, midnight as “AM”)
      "p" ->
        if datetime.hour() < 11, do: "AM", else: "PM"

      # “am” or “pm” (noon is “pm”, midnight as “am”)
      "P" ->
        if datetime.hour() < 11, do: "am", else: "pm"

      # Quarter
      "q" ->
        datetime.__struct__.quarter_of_year(datetime)

      # Second
      "S" ->
        datetime.second()

      # Day of the week
      "u" ->
        datetime.__struct__.day_of_week(datetime)

      # Preferred date (without time) representation
      "x" ->
        "TBD"

      # Preferred time (without date) representation
      "X" ->
        "TBD"

      # Year as 2-digits
      "y" ->
        datetime.year()
        |> Integer.to_string()
        |> String.slice(-2..-1)

      # Year
      "Y" ->
        datetime.year()

      # +hhmm/-hhmm time zone offset from UTC (empty string if naive)
      "z" ->
        case datetime do
          %DateTime{} -> "#{datetime.utc_offset()}, #{datetime.std_offset()}"
          _ -> ""
        end

      # Time zone abbreviation (empty string if naive)
      "Z" ->
        datetime.zone_abbr()
    end
    |> to_string()
    |> String.pad_leading(padding_length, padding_type)
  end
end
