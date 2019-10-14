# NimbleStrftime

`nimble_strftime` is a simple and fast library for formatting datetimes into
strings based on the `strftime` tool found on UNIX-like systems.

## Examples

Once installed, you can format your calendar types right away:

```elixir
iex> datetime = ~U[2019-08-26 13:52:06.0Z]
# year(2 digits)-month-day hour(in a 12 hour clock):minute:second AM/PM
iex> NimbleStrftime.format(datetime, "%y-%m-%d %I:%M:%S %p")
"19-08-26 01:52:06 PM"

# day_of_week_abbreviated, month day_of_month year
iex> NimbleStrftime.format(datetime, "%a, %B %d %Y")
"mon, august 26 2019"

# preferred datetime, default setting "%Y-%m-%d %H:%M:%S"
iex> NimbleStrftime.format(datetime, "%c")
"2019-08-26 13:52:06"
```

You can also pass configuration parameters to set preferred formats,
set the size of abbreviated names and change the names of months,
week days, am and pm:

```elixir
iex> datetime = ~U[2019-08-26 13:52:06.0Z]

# preferred datetime, configured to something else
iex> NimbleStrftime.format(datetime, "%c", preferred_datetime: "%H:%M:%S %d-%m-%y")
"13:52:06 26-08-19"

# day_of_week configured to another language
iex> NimbleStrftime.format(
...>  datetime,
...>  "%A",
...>  day_of_week_names: fn day_of_week ->
...>    {"segunda-feira", "terça-feira", "quarta-feira", "quinta-feira",
...>    "sexta-feira", "sábado", "domingo"}
...>    |> elem(day_of_week - 1)
...>  end
...>)
"segunda-feira"

# month_name with settings for custom abbreviation and names
iex> NimbleStrftime.format(
...>  datetime,
...>  "%B",
...>  abbreviated_month_names: fn month ->
...>    {"янв", "февр", "март", "апр", "май", "июнь",
...>    "июль", "авг", "сент", "окт", "нояб", "дек"}
...>    |> elem(month - 1)
...>  end
...>)
# => "авг"
```

For more information, please consult the [online documentation](https://hexdocs.pm/nimble_strftime/NimbleStrftime.html)

## Installation

Add `nimble_strftime` to your dependencies:

```elixir
def deps do
  [
    {:nimble_strftime, "~> 0.1.0"}
  ]
end
```

## Nimble*

Other nimble libraries by Plataformatec:

  * [NimbleParsec](https://github.com/plataformatec/nimble_parsec) - simple and fast parser combinators
  * [NimbleCSV](https://github.com/plataformatec/nimble_csv) - simple and fast CSV parsing

# License

Copyright 2019 Plataformatec

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
