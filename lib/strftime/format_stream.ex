defmodule Strftime.FormatStream do
  @moduledoc """
  Module that represents and prepares a Strftime `stream`.

  # What is a 'stream'?
    A stream, in this case is a sequence of bytes that may represent a
  date formatting instruction, the term was borrowed from the concept of
  data streams that work in the same principles as the format stream does

  # Format stream specification
    A stream here is made of up to 4 sections of which only the
  width has variable length
  stream sections
  <style>
    .stream-diagram {
      border: 1px solid;
      display: inline-block
    }
    .diagram-section {
      padding: 0em 1em;
      border-left: 1px solid;
      border-right: 1px solid;
      font-weight: 900;
    }
    .section-bytes {
      font-weight: 600;
    }
  </style>
  <div class="stream-diagram">
    <span class="diagram-section">
      init<span class="section-bytes">::1 byte</span>
    </span>
    <span class="diagram-section">
      pad<span class="section-bytes">::0 to 1byte</span>
    </span>
    <span class="diagram-section">
      width<span class="section-bytes">::0 to n bytes </span>
    </span>
    <span class="diagram-section">
      finalizer<span class="section-bytes">::1 byte or string end</span>
    </span>
  </div>
  * `init`: always the `%` char it signals the start of a section of formatted date
  * `pad`: can be one of the following charaters `0`, `-`, `_` it can also be empty
  * `width`: a sequence of numeric chars, can only start with zero if a pad was received in the previous section
  * `finalizer`: a non-numeric character that represents the formatting option, if the string ends short the format will be considered an empty string and the stream will end

  """

  @typedoc """
  A parsed(or partially parsed) format stream it holds the instructions to apply
  the date formatting once the stream was fully traversed
  * `format`: the final character of the stream that decides the formatting of the datetime
  * `width`: length the formatted stream will yield, some formats have default widths
  * `pad`: character that will be used on padding the result to the desired width, some formats have default pads
    * the `-` pad is a special case as it indicates the result must have no padding at all, nullifies the width
  * `section`: holds the parsed string as a fallback in case the stream holds invalid formatting instructions
  """
  @type t :: %__MODULE__{
          format: nil | String.t(),
          width: nil | integer(),
          pad: nil | String.t(),
          section: list(String.t())
        }
  defstruct [:format, :width, :pad, section: ["%"]]
end
