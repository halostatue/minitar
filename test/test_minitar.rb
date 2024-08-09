#!/usr/bin/env ruby

require "minitar"
require "minitest_helper"
require "zlib"

class TestMinitar < Minitest::Test
  FILE_2004 = Time.utc(2004).to_i

  def test_pack_as_file
    input = [
      ["path", nil],
      ["test", "test"],
      ["extra/test", "extra/test"],
      [{name: "empty2004", mtime: FILE_2004, mode: 0o755}, ""]
    ]

    writer = StringIO.new
    Minitar::Output.open(writer) do |out_stream|
      input.each do |(name, data)|
        Minitar.pack_as_file(name, data, out_stream)
      end
    end

    expected = [
      {name: "path", size: 0, mode: 0o755},
      {name: "test", size: 4, mode: 0o644, data: "test"},
      {name: "extra/test", size: 10, mode: 0o0644, data: "extra/test"},
      {name: "empty2004", size: 0, mode: 0o755, mtime: FILE_2004, nil: true}
    ]

    count = 0
    reader = StringIO.new(writer.string)
    Minitar.open(reader) do |stream|
      stream.each.with_index do |entry, i|
        assert_kind_of Minitar::Reader::EntryStream, entry

        assert_equal expected[i][:name], entry.name
        assert_equal expected[i][:size], entry.size
        assert_equal expected[i][:mode], entry.mode

        if expected[i].key?(:mtime)
          assert_equal expected[i][:mtime], entry.mtime
        end

        if expected[i].key?(:data)
          assert_equal expected[i][:data], entry.read
        end

        if expected[i].key?(:nil)
          assert_nil entry.read
        end

        count += 1
      end
    end

    assert_equal expected.size, count
  end
end
