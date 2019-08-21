defmodule Strftime.FormatOptionsTest do
  use ExUnit.Case
  alias Strftime.FormatOptions

  describe "am_name/1" do
    test "return \"am\" on default settings" do
      assert FormatOptions.am_name(%FormatOptions{}) == "am"
    end

    test "return custom am name on different settings" do
      assert FormatOptions.am_name(%FormatOptions{am_pm_names: {"a", "p"}}) == "a"
    end
  end

  describe "pm_name/1" do
    test "return \"pm\" on default settings" do
      assert FormatOptions.pm_name(%FormatOptions{}) == "pm"
    end

    test "return custom am name on different settings" do
      assert FormatOptions.pm_name(%FormatOptions{am_pm_names: {"a", "p"}}) == "p"
    end
  end

  describe "month_name/2" do
    test "return the name of the month in english on default settings" do
      assert FormatOptions.month_name(12, %FormatOptions{}) == "December"
    end

    test "return the name of the month in the configured set" do
      alternate_months =
        ~w(Janeiro Fevereiro Março Abril Maio Junho Julho Agosto Setembro Outubro Novembro Dezembro)

      assert(
        FormatOptions.month_name(1, %FormatOptions{month_names: alternate_months}) == "Janeiro"
      )
    end
  end

  describe "month_name_abbreviated/2" do
    test "return the name of the month abbreviated to 3 chars when abbreviation_size is not configured" do
      assert FormatOptions.month_name_abbreviated(11, %FormatOptions{}) == "Nov"
    end

    test "return the name of the month abbreviated to the configured abbreviation_size" do
      assert(
        FormatOptions.month_name_abbreviated(
          11,
          %FormatOptions{abbreviation_size: 6}
        ) == "Novemb"
      )
    end
  end

  describe "day_of_week_name/2" do
    test "return the name of the day of the week in english on default settings" do
      assert FormatOptions.day_of_week_name(5, %FormatOptions{}) == "Friday"
    end

    test "return the name of the day of the week in the configured set" do
      alternate_days_of_week = ~w(понедельник вторник среда четверг пятница суббота воскресенье)

      assert(
        FormatOptions.day_of_week_name(7, %FormatOptions{
          day_of_week_names: alternate_days_of_week
        }) == "воскресенье"
      )
    end
  end

  describe "day_of_week_name_abbreviated/2" do
    test "return the name of the day of the week abbreviated to 3 chars when abbreviation_size is not configured" do
      assert FormatOptions.day_of_week_name_abbreviated(1, %FormatOptions{}) == "Mon"
    end

    test "return the name of the day of the week abbreviated to the configured abbreviation_size" do
      assert(
        FormatOptions.day_of_week_name_abbreviated(
          1,
          %FormatOptions{abbreviation_size: 4}
        ) == "Mond"
      )
    end
  end
end
