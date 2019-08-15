defmodule Strftime.FormatStream do
  defstruct [:format, :width, :pad, section: "%"]

  def stream("", format_stream), do: {format_stream, ""}

  def stream("-" <> rest, format_stream = %{pad: nil}) do
    stream(rest, %{format_stream | pad: "-", section: format_stream.section <> "-"})
  end

  def stream("0" <> rest, format_stream = %{pad: nil}) do
    stream(rest, %{format_stream | pad: "0", section: format_stream.section <> "0"})
  end

  def stream("_" <> rest, format_stream = %{pad: nil}) do
    stream(rest, %{format_stream | pad: " ", section: format_stream.section <> "_"})
  end

  def stream(<<digit::utf8, rest::binary>>, format_stream = %{pad: pad})
      when digit > 47 and digit < 58 do
    new_width =
      case pad do
        "-" -> 0
        _ -> (format_stream.width || 0) * 10 + (digit - 48)
      end

    stream(rest, %{format_stream | width: new_width, section: format_stream.section <> <<digit>>})
  end

  def stream(<<format::binary-1, rest::binary>>, format_stream) do
    {%{format_stream | format: format}, rest}
  end
end
