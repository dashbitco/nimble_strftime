defmodule Strftime.FormatOptions do
  alias Strftime.FormatOptions

  defstruct preferred_date: Application.get_env(:strftime, :preferred_date, "%Y-%m-%d"),
            preferred_time: Application.get_env(:strftime, :preferred_time, "%H:%M:%S"),
            preferred_datetime:
              Application.get_env(:strftime, :preferred_datetime, "%Y-%m-%d %H:%M:%S"),
            am_pm_names: Application.get_env(:strftime, :am_pm_names, {"am", "pm"}),
            month_names:
              Application.get_env(
                :strftime,
                :month_names,
                ~w(January February March April May June July August September October November December)
              ),
            day_of_week_names:
              Application.get_env(
                :strftime,
                :day_of_week_names,
                ~w(Monday Tuesday Wednesday Thursday Friday Saturday Sunday)
              ),
            abbreviation_size: 3

  @type options :: [option]
  @type option ::
          {:preferred_date, String.t()}
          | {:preferred_time, String.t()}
          | {:preferred_datetime, String.t()}
          | {:am_pm_names, {String.t(), String.t()}}
          | {:month_names, list(String.t())}
          | {:day_of_week_names, list(String.t())}

  def am_name(options = %FormatOptions{}), do: elem(options.am_pm_names, 0)

  def pm_name(options = %FormatOptions{}), do: elem(options.am_pm_names, 1)

  def month_name(index, options = %FormatOptions{}) when index > 0 and index < 13 do
    Enum.at(options.month_names, index - 1)
  end

  def month_name_abbreviated(index, options = %FormatOptions{}) do
    String.slice(month_name(index, options), 0..(options.abbreviation_size - 1))
  end

  def day_of_week_name(index, options = %FormatOptions{}) when index > 0 and index < 8 do
    Enum.at(options.day_of_week_names, index - 1)
  end

  def day_of_week_name_abbreviated(index, options = %FormatOptions{}) do
    String.slice(day_of_week_name(index, options), 0..(options.abbreviation_size - 1))
  end
end
