defmodule NimbleStrftimeTest do
  use ExUnit.Case
  doctest NimbleStrftime

  describe "format/3" do
    test "return received string if there is no datetime formatting to be found in it" do
      assert NimbleStrftime.format(~N[2019-08-20 15:47:34.001], "muda string") == "muda string"
    end

    test "format all time zones blank when receiving a NaiveDateTime" do
      assert NimbleStrftime.format(~N[2019-08-15 17:07:57.001], "%z%Z") == ""
    end

    test "raise error when trying to format a date with a map that has no date fields" do
      time_without_date = %{hour: 15, minute: 47, second: 34, microsecond: {0, 0}}

      assert_raise(KeyError, fn -> NimbleStrftime.format(time_without_date, "%x") end)
    end

    test "raise error when trying to format a time with a map that has no time fields" do
      date_without_time = %{year: 2019, month: 8, day: 20}

      assert_raise(KeyError, fn -> NimbleStrftime.format(date_without_time, "%X") end)
    end

    test "raise error when the format is invalid" do
      assert_raise(FunctionClauseError, fn ->
        NimbleStrftime.format(~N[2019-08-20 15:47:34.001], "%-2-ç")
      end)
    end

    test "raise error when the preferred_datetime calls itself" do
      assert_raise(RuntimeError, fn ->
        NimbleStrftime.format(~N[2019-08-20 15:47:34.001], "%c", preferred_datetime: "%c")
      end)
    end

    test "raise error when the preferred_date calls itself" do
      assert_raise(RuntimeError, fn ->
        NimbleStrftime.format(~N[2019-08-20 15:47:34.001], "%x", preferred_date: "%x")
      end)
    end

    test "raise error when the preferred_time calls itself" do
      assert_raise(RuntimeError, fn ->
        NimbleStrftime.format(~N[2019-08-20 15:47:34.001], "%X", preferred_time: "%X")
      end)
    end

    test "raise error when the preferred formats create a circular chain" do
      assert_raise(RuntimeError, fn ->
        NimbleStrftime.format(~N[2019-08-20 15:47:34.001], "%c",
          preferred_datetime: "%x",
          preferred_date: "%X",
          preferred_time: "%c"
        )
      end)
    end

    test "format with no errors is the preferred formats are included multiple times on the same string" do
      assert(
        NimbleStrftime.format(~N[2019-08-15 17:07:57.001], "%c %c %x %x %X %X") ==
          "2019-08-15 17:07:57 2019-08-15 17:07:57 2019-08-15 2019-08-15 17:07:57 17:07:57"
      )
    end

    test "ignore width when receiving the `-` padding option" do
      assert NimbleStrftime.format(~T[17:07:57.001], "%-999M") == "7"
    end

    test "format time zones correctly when receiving a DateTime" do
      datetime_with_zone = %DateTime{
        year: 2019,
        month: 8,
        day: 15,
        zone_abbr: "EEST",
        hour: 17,
        minute: 7,
        second: 57,
        microsecond: {0, 0},
        utc_offset: 7200,
        std_offset: 3600,
        time_zone: "UK"
      }

      assert NimbleStrftime.format(datetime_with_zone, "%z %Z") == "+0300 EEST"
    end

    test "format AM and PM correctly on the %P and %p options" do
      am_time_almost_pm = ~U[2019-08-26 11:59:59.001Z]
      pm_time = ~U[2019-08-26 12:00:57.001Z]
      pm_time_almost_am = ~U[2019-08-26 23:59:57.001Z]
      am_time = ~U[2019-08-26 00:00:01.001Z]

      assert NimbleStrftime.format(am_time_almost_pm, "%P %p") == "am AM"
      assert NimbleStrftime.format(pm_time, "%P %p") == "pm PM"
      assert NimbleStrftime.format(pm_time_almost_am, "%P %p") == "pm PM"
      assert NimbleStrftime.format(am_time, "%P %p") == "am AM"
    end

    test "format all weekdays correctly with %A and %a formats" do
      sunday = ~U[2019-08-25 11:59:59.001Z]
      monday = ~U[2019-08-26 11:59:59.001Z]
      tuesday = ~U[2019-08-27 11:59:59.001Z]
      wednesday = ~U[2019-08-28 11:59:59.001Z]
      thursday = ~U[2019-08-29 11:59:59.001Z]
      friday = ~U[2019-08-30 11:59:59.001Z]
      saturday = ~U[2019-08-31 11:59:59.001Z]

      assert NimbleStrftime.format(sunday, "%A %a") == "Sunday Sun"
      assert NimbleStrftime.format(monday, "%A %a") == "Monday Mon"
      assert NimbleStrftime.format(tuesday, "%A %a") == "Tuesday Tue"
      assert NimbleStrftime.format(wednesday, "%A %a") == "Wednesday Wed"
      assert NimbleStrftime.format(thursday, "%A %a") == "Thursday Thu"
      assert NimbleStrftime.format(friday, "%A %a") == "Friday Fri"
      assert NimbleStrftime.format(saturday, "%A %a") == "Saturday Sat"
    end

    test "format all months correctly with the %B and %b formats" do
      assert NimbleStrftime.format(%{month: 1}, "%B %b") == "January Jan"
      assert NimbleStrftime.format(%{month: 2}, "%B %b") == "February Feb"
      assert NimbleStrftime.format(%{month: 3}, "%B %b") == "March Mar"
      assert NimbleStrftime.format(%{month: 4}, "%B %b") == "April Apr"
      assert NimbleStrftime.format(%{month: 5}, "%B %b") == "May May"
      assert NimbleStrftime.format(%{month: 6}, "%B %b") == "June Jun"
      assert NimbleStrftime.format(%{month: 7}, "%B %b") == "July Jul"
      assert NimbleStrftime.format(%{month: 8}, "%B %b") == "August Aug"
      assert NimbleStrftime.format(%{month: 9}, "%B %b") == "September Sep"
      assert NimbleStrftime.format(%{month: 10}, "%B %b") == "October Oct"
      assert NimbleStrftime.format(%{month: 11}, "%B %b") == "November Nov"
      assert NimbleStrftime.format(%{month: 12}, "%B %b") == "December Dec"
    end

    test "format all weekdays correctly on %A with day_of_week_names option" do
      sunday = ~U[2019-08-25 11:59:59.001Z]
      monday = ~U[2019-08-26 11:59:59.001Z]
      tuesday = ~U[2019-08-27 11:59:59.001Z]
      wednesday = ~U[2019-08-28 11:59:59.001Z]
      thursday = ~U[2019-08-29 11:59:59.001Z]
      friday = ~U[2019-08-30 11:59:59.001Z]
      saturday = ~U[2019-08-31 11:59:59.001Z]

      day_of_week_names = fn day_of_week ->
        {"segunda-feira", "terça-feira", "quarta-feira", "quinta-feira", "sexta-feira", "sábado",
         "domingo"}
        |> elem(day_of_week - 1)
      end

      assert NimbleStrftime.format(sunday, "%A", day_of_week_names: day_of_week_names) ==
               "domingo"

      assert NimbleStrftime.format(monday, "%A", day_of_week_names: day_of_week_names) ==
               "segunda-feira"

      assert NimbleStrftime.format(tuesday, "%A", day_of_week_names: day_of_week_names) ==
               "terça-feira"

      assert NimbleStrftime.format(wednesday, "%A", day_of_week_names: day_of_week_names) ==
               "quarta-feira"

      assert NimbleStrftime.format(thursday, "%A", day_of_week_names: day_of_week_names) ==
               "quinta-feira"

      assert NimbleStrftime.format(friday, "%A", day_of_week_names: day_of_week_names) ==
               "sexta-feira"

      assert NimbleStrftime.format(saturday, "%A", day_of_week_names: day_of_week_names) ==
               "sábado"
    end

    test "format all months correctly on the %B with month_names option" do
      month_names = fn month ->
        {"январь", "февраль", "март", "апрель", "май", "июнь", "июль", "август", "сентябрь",
         "октябрь", "ноябрь", "декабрь"}
        |> elem(month - 1)
      end

      assert NimbleStrftime.format(%{month: 1}, "%B", month_names: month_names) == "январь"
      assert NimbleStrftime.format(%{month: 2}, "%B", month_names: month_names) == "февраль"
      assert NimbleStrftime.format(%{month: 3}, "%B", month_names: month_names) == "март"
      assert NimbleStrftime.format(%{month: 4}, "%B", month_names: month_names) == "апрель"
      assert NimbleStrftime.format(%{month: 5}, "%B", month_names: month_names) == "май"
      assert NimbleStrftime.format(%{month: 6}, "%B", month_names: month_names) == "июнь"
      assert NimbleStrftime.format(%{month: 7}, "%B", month_names: month_names) == "июль"
      assert NimbleStrftime.format(%{month: 8}, "%B", month_names: month_names) == "август"
      assert NimbleStrftime.format(%{month: 9}, "%B", month_names: month_names) == "сентябрь"
      assert NimbleStrftime.format(%{month: 10}, "%B", month_names: month_names) == "октябрь"
      assert NimbleStrftime.format(%{month: 11}, "%B", month_names: month_names) == "ноябрь"
      assert NimbleStrftime.format(%{month: 12}, "%B", month_names: month_names) == "декабрь"
    end

    test "format all weekdays correctly on the %a format with abbreviated_day_of_week_names option" do
      sunday = ~U[2019-08-25 11:59:59.001Z]
      monday = ~U[2019-08-26 11:59:59.001Z]
      tuesday = ~U[2019-08-27 11:59:59.001Z]
      wednesday = ~U[2019-08-28 11:59:59.001Z]
      thursday = ~U[2019-08-29 11:59:59.001Z]
      friday = ~U[2019-08-30 11:59:59.001Z]
      saturday = ~U[2019-08-31 11:59:59.001Z]

      abbreviated_day_of_week_names = fn day_of_week ->
        {"seg", "ter", "qua", "qui", "sex", "sáb", "dom"}
        |> elem(day_of_week - 1)
      end

      assert NimbleStrftime.format(sunday, "%a",
               abbreviated_day_of_week_names: abbreviated_day_of_week_names
             ) == "dom"

      assert NimbleStrftime.format(monday, "%a",
               abbreviated_day_of_week_names: abbreviated_day_of_week_names
             ) == "seg"

      assert NimbleStrftime.format(tuesday, "%a",
               abbreviated_day_of_week_names: abbreviated_day_of_week_names
             ) == "ter"

      assert NimbleStrftime.format(wednesday, "%a",
               abbreviated_day_of_week_names: abbreviated_day_of_week_names
             ) == "qua"

      assert NimbleStrftime.format(thursday, "%a",
               abbreviated_day_of_week_names: abbreviated_day_of_week_names
             ) == "qui"

      assert NimbleStrftime.format(friday, "%a",
               abbreviated_day_of_week_names: abbreviated_day_of_week_names
             ) == "sex"

      assert NimbleStrftime.format(saturday, "%a",
               abbreviated_day_of_week_names: abbreviated_day_of_week_names
             ) == "sáb"
    end

    test "format all months correctly on the %b format with abbreviated_month_names option" do
      abbreviated_month_names = fn month ->
        {"янв", "февр", "март", "апр", "май", "июнь", "июль", "авг", "сент", "окт", "нояб", "дек"}
        |> elem(month - 1)
      end

      assert NimbleStrftime.format(%{month: 1}, "%b",
               abbreviated_month_names: abbreviated_month_names
             ) == "янв"

      assert NimbleStrftime.format(%{month: 2}, "%b",
               abbreviated_month_names: abbreviated_month_names
             ) == "февр"

      assert NimbleStrftime.format(%{month: 3}, "%b",
               abbreviated_month_names: abbreviated_month_names
             ) == "март"

      assert NimbleStrftime.format(%{month: 4}, "%b",
               abbreviated_month_names: abbreviated_month_names
             ) == "апр"

      assert NimbleStrftime.format(%{month: 5}, "%b",
               abbreviated_month_names: abbreviated_month_names
             ) == "май"

      assert NimbleStrftime.format(%{month: 6}, "%b",
               abbreviated_month_names: abbreviated_month_names
             ) == "июнь"

      assert NimbleStrftime.format(%{month: 7}, "%b",
               abbreviated_month_names: abbreviated_month_names
             ) == "июль"

      assert NimbleStrftime.format(%{month: 8}, "%b",
               abbreviated_month_names: abbreviated_month_names
             ) == "авг"

      assert NimbleStrftime.format(%{month: 9}, "%b",
               abbreviated_month_names: abbreviated_month_names
             ) == "сент"

      assert NimbleStrftime.format(%{month: 10}, "%b",
               abbreviated_month_names: abbreviated_month_names
             ) == "окт"

      assert NimbleStrftime.format(%{month: 11}, "%b",
               abbreviated_month_names: abbreviated_month_names
             ) == "нояб"

      assert NimbleStrftime.format(%{month: 12}, "%b",
               abbreviated_month_names: abbreviated_month_names
             ) == "дек"
    end

    test "microseconds format ignores padding and width options" do
      datetime = ~U[2019-08-15 17:07:57.001234Z]
      assert NimbleStrftime.format(datetime, "%f") == "001234"
      assert NimbleStrftime.format(datetime, "%f") == NimbleStrftime.format(datetime, "%_20f")
      assert NimbleStrftime.format(datetime, "%f") == NimbleStrftime.format(datetime, "%020f")
      assert NimbleStrftime.format(datetime, "%f") == NimbleStrftime.format(datetime, "%-f")
    end

    test "microseconds format formats properly dates with different precisions" do
      assert NimbleStrftime.format(~U[2019-08-15 17:07:57.5Z], "%f") == "5"
      assert NimbleStrftime.format(~U[2019-08-15 17:07:57.45Z], "%f") == "45"
      assert NimbleStrftime.format(~U[2019-08-15 17:07:57.345Z], "%f") == "345"
      assert NimbleStrftime.format(~U[2019-08-15 17:07:57.2345Z], "%f") == "2345"
      assert NimbleStrftime.format(~U[2019-08-15 17:07:57.12345Z], "%f") == "12345"
      assert NimbleStrftime.format(~U[2019-08-15 17:07:57.012345Z], "%f") == "012345"
    end

    test "microseconds formats properly different precisions of zero" do
      assert NimbleStrftime.format(~N[2019-08-15 17:07:57.0], "%f") == "0"
      assert NimbleStrftime.format(~N[2019-08-15 17:07:57.00], "%f") == "00"
      assert NimbleStrftime.format(~N[2019-08-15 17:07:57.000], "%f") == "000"
      assert NimbleStrftime.format(~N[2019-08-15 17:07:57.0000], "%f") == "0000"
      assert NimbleStrftime.format(~N[2019-08-15 17:07:57.00000], "%f") == "00000"
      assert NimbleStrftime.format(~N[2019-08-15 17:07:57.000000], "%f") == "000000"
    end

    test "microseconds returns a single zero if there's no precision at all" do
      assert NimbleStrftime.format(~N[2019-08-15 17:07:57], "%f") == "0"
    end

    test "return the formatted datetime when all format options and modifiers are received" do
      assert NimbleStrftime.format(
               ~U[2019-08-15 17:07:57.001Z],
               "%04% %a %A %b %B %-3c %d %f %H %I %j %m %_5M %p %P %q %S %u %x %X %y %Y %z %Z"
             ) ==
               "000% Thu Thursday Aug August 2019-08-15 17:07:57 15 001 17 05 227 08     7 PM pm 3 57 4 2019-08-15 17:07:57 19 2019 +0000 UTC"
    end

    test "format according to received custom configs" do
      assert NimbleStrftime.format(
               ~U[2019-08-15 17:07:57.001Z],
               "%A %a %p %B %b %c %x %X",
               am_pm_names: fn
                 :am -> "a"
                 :pm -> "p"
               end,
               month_names: fn month ->
                 {"Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho", "Julho", "Agosto",
                  "Setembro", "Outubro", "Novembro", "Dezembro"}
                 |> elem(month - 1)
               end,
               day_of_week_names: fn day_of_week ->
                 {"понедельник", "вторник", "среда", "четверг", "пятница", "суббота",
                  "воскресенье"}
                 |> elem(day_of_week - 1)
               end,
               abbreviated_month_names: fn month ->
                 {"Jan", "Fev", "Mar", "Abr", "Mai", "Jun", "Jul", "Ago", "Set", "Out", "Nov",
                  "Dez"}
                 |> elem(month - 1)
               end,
               abbreviated_day_of_week_names: fn day_of_week ->
                 {"ПНД", "ВТР", "СРД", "ЧТВ", "ПТН", "СБТ", "ВСК"}
                 |> elem(day_of_week - 1)
               end,
               preferred_date: "%05Y-%m-%d",
               preferred_time: "%M:%_3H%S",
               preferred_datetime: "%%"
             ) == "четверг ЧТВ P Agosto Ago % 02019-08-15 07: 1757"
    end
  end
end
