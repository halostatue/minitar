#!/usr/bin/env ruby

require "minitar"
require "minitest_helper"
require "base64"
require "zlib"

class TestIssue46 < Minitest::Test
  FILETIMES = Time.utc(2004).to_i

  superlong_name = (["0123456789abcde"] * 33).join("/")

  SUPERLONG_CONTENTS = {
    superlong_name => {size: 496, mode: 0o644},
    "endfile" => {size: 0, mode: 0o644}
  }

  def test_each_works
    Minitar::Input.open(open_fixture("issue_46")) do |stream|
      outer = 0
      stream.each.with_index do |entry, i|
        assert_kind_of Minitar::Reader::EntryStream, entry
        assert SUPERLONG_CONTENTS.key?(entry.name), "File #{entry.name} not defined"

        assert_equal SUPERLONG_CONTENTS[entry.name][:size],
          entry.size,
          "File sizes sizes do not match: #{entry.name}"

        assert_modes_equal(SUPERLONG_CONTENTS[entry.name][:mode],
          entry.mode, entry.name)
        assert_equal FILETIMES, entry.mtime, "entry.mtime"

        outer += 1
      end

      assert_equal 2, outer
    end
  end
end
