defmodule NimbleStrftime.FormatOptions do
  @moduledoc """
  Module for setting and retrieving configurable formatting options
  """
  alias NimbleStrftime.FormatOptions

  @typedoc """
  Struct that holds configuration options, loads the application defaults on the configs
  """
  @type t :: %__MODULE__{
          preferred_date: String.t(),
          preferred_time: String.t(),
          preferred_datetime: String.t(),
          am_pm_names: {String.t(), String.t()},
          month_names: list(String.t()),
          day_of_week_names: list(String.t()),
          abbreviation_size: integer(),
          preferred_datetime_invoked: true | false,
          preferred_date_invoked: true | false,
          preferred_time_invoked: true | false
        }
  defstruct preferred_date: "%Y-%m-%d",
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

  @typedoc "Accepted configuration options to be used by NimbleStrftime"
  @type options :: [option]

  @typedoc "Accepted configuration option to be used by NimbleStrftime"
  @type option ::
          {:preferred_date, String.t()}
          | {:preferred_time, String.t()}
          | {:preferred_datetime, String.t()}
          | {:am_pm_names, {String.t(), String.t()}}
          | {:month_names, list(String.t())}
          | {:day_of_week_names, list(String.t())}
          | {:abbreviation_size, integer()}

  @doc "Returns the `am_name` configured for the received format_options struct"
  @spec am_name(t()) :: String.t()
  def am_name(format_options = %FormatOptions{}), do: elem(format_options.am_pm_names, 0)

  @doc "Returns the `pm_name` configured for the received format_options struct"
  @spec pm_name(t()) :: String.t()
  def pm_name(format_options = %FormatOptions{}), do: elem(format_options.am_pm_names, 1)

  @doc "Returns the name of the received month number, based on the received format_options struct"
  @spec month_name(integer(), t()) :: String.t()
  def month_name(index, format_options = %FormatOptions{}) when index > 0 and index < 13 do
    Enum.at(format_options.month_names, index - 1)
  end

  @doc "Same as `month_name` but shortened to the configured `:abbreviation_size`"
  @spec month_name_abbreviated(integer(), t()) :: String.t()
  def month_name_abbreviated(index, format_options = %FormatOptions{}) do
    String.slice(month_name(index, format_options), 0..(format_options.abbreviation_size - 1))
  end

  @doc "Returns the name of the received week day number, based on the received options struct"
  @spec day_of_week_name(integer(), t()) :: String.t()
  def day_of_week_name(index, format_options = %FormatOptions{}) when index > 0 and index < 8 do
    Enum.at(format_options.day_of_week_names, index - 1)
  end

  @doc "Same as `day_of_week_name` but shortened to the configured `:abbreviation_size`"
  @spec day_of_week_name_abbreviated(integer(), t()) :: String.t()
  def day_of_week_name_abbreviated(index, format_options = %FormatOptions{}) do
    String.slice(
      day_of_week_name(index, format_options),
      0..(format_options.abbreviation_size - 1)
    )
  end
end
