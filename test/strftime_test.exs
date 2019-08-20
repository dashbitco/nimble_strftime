defmodule StrftimeTest do
  use ExUnit.Case
  doctest Strftime

  describe "format/3" do
    test "format all time zones blank when receiving a NaiveDateTime" do
      assert Strftime.format(~N[2019-08-15 17:07:57.001], "%z%Z") == ""
    end

    test "return `hour:minute:seconds PM` when receiving `%I:%M:%S %p`" do
      assert Strftime.format(~U[2019-08-15 17:07:57.001Z], "%I:%M:%S %p") == "05:07:57 PM"
    end

    test "ignore width when receiving the `-` padding option" do
      assert Strftime.format(~T[17:07:57.001], "%-999M") == "7"
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

      assert Strftime.format(datetime_with_zone, "%z %Z") == "+0300 EEST"
    end

    test "return the formatted datetime when all format options and modifiers are received" do
      assert Strftime.format(
               ~U[2019-08-15 17:07:57.001Z],
               "%04% %a %A %b %B %-3c %d %f %H %I %J %m %_5M %p %P %q %S %u %x %X %y %Y %z %Z"
             ) ==
               "000% Thu Thursday Aug August 2019-08-15 17:07:57 15 1000 17 05 %J 08     7 PM pm 3 57 04 2019-08-15 17:07:57 19 2019 +0000 UTC"
    end

    test "format according to received custom configs" do
      assert Strftime.format(
               ~U[2019-08-15 17:07:57.001Z],
               "%A %p %B %c %x %X",
               am_pm_names: {"a", "p"},
               month_names:
                 ~w(Janeiro Fevereiro Março Abril Maio Junho Julho Agosto Setembro Outubro Novembro Dezembro),
               day_of_week_names:
                 ~w(понедельник вторник среда четверг пятница суббота воскресенье),
               preferred_date: "%05Y-%m-%d",
               preferred_time: "%M:%_3H%S",
               preferred_datetime: "%%"
             ) == "четверг P Agosto % 02019-08-15 07: 1757"
    end
  end
end
