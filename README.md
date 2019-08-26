# NimbleStrftime

  `nimble_strftime` is a simple and fast library for formatting datetimes into
strings using the Strftime tool found on unix-like systems as a basis

  `nimble_strftime` is made purely on elixir with no dependency on other libraries
and uses binary matchers things that combined provide the following benefits:
  * the binary matchers take advantage of the Erlang VM optimizations what allows for fast performance and low memory usage
  * users need nothing else to start using `nimble_strftime` as it depends neither on the operating system nor on other libraries

## Examples
You can start formatting your dates without no settings as every allowed setting has a default
```elixir
datetime = ~U[2019-08-26 13:52:06.0Z]
# year(2 digits)-month-day hour(in a 12 hour clock):minute:second AM/PM
NimbleStrftime.format(datetime, "%y-%m-%d %I:%M:%S %p")
# => "19-08-26 01:52:06 PM"

# day_of_week_abbreviated, month day_of_month year
NimbleStrftime.format(datetime, "%a, %B %d %Y")
# => "mon, august 26 2019"

# preferred datetime, default setting "%Y-%m-%d %H:%M:%S"
NimbleStrftime.format(datetime, "%c")
# => "2019-08-26 13:52:06"
```

you can also pass configuration parameters to set preferred formats, set the size of abbreviated names and change the names of months, week days, am and pm
```elixir
datetime = ~U[2019-08-26 13:52:06.0Z]

# preferred datetime, configured to something else
NimbleStrftime.format(
  datetime,
  "%c",
  preferred_datetime: "%H:%M:%S %d-%m-%y"
)
# => "13:52:06 26-08-19"

# day_of_week configured to another language
NimbleStrftime.format(
  datetime,
  "%A",
  day_of_week_names: ~w(
    segunda-feira
    terça-feira
    quarta-feira
    quinta-feira
    sexta-feira
    sábado
    domingo
  )
)
# => "segunda-feira"

# month_name with settings for custom abbreviation and names
NimbleStrftime.format(
  datetime,
  "%B",
  abbreviation_size: 2,
  month_names: ~w(
    январь
    февраль
    март
    апрель
    май
    июнь
    июль
    август
    сентябрь
    октябрь
    ноябрь
    декабрь
  )
)
# => "ав"
```

## Installation
add `nimble_strftime` to your dependencies
```elixir
def deps do
  [
    {:nimble_strftime, github: "plataformatec/nimble_strftime"}
  ]
end
```

# License
Copyright 2019 Plataformatec

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.