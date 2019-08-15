defmodule Strftime.FormatStreamTest do
  use ExUnit.Case
  alias Strftime.FormatStream

  describe "stream/2" do
    test "return {received_format_stream, \"\"} when receiving an empty string" do
      format_stream = %FormatStream{format: nil, width: 5, pad: "_", section: "%_5"}
      assert FormatStream.stream("", format_stream) == {format_stream, ""}
    end

    test "return {updated_format_stream, \"\"} when receiving a valid stream from start to end" do
      expected_stream = %FormatStream{format: "A", width: 7, pad: "0", section: "%07A"}
      assert FormatStream.stream("07A", %FormatStream{}) == {expected_stream, ""}
    end

    test "keep format nil when the string ends too soon" do
      expected_stream = %FormatStream{format: nil, width: 7, pad: "0", section: "%07"}
      assert FormatStream.stream("07", %FormatStream{}) == {expected_stream, ""}
    end

    test "return the rest of the string after the stream ends" do
      assert {_stream, "-streamover"} = FormatStream.stream("07A-streamover", %FormatStream{})
    end
  end
end
