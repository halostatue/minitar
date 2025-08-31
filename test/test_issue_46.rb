# frozen_string_literal: true

require "minitest_helper"

class TestIssue46 < Minitest::Test
  SUPERLONG_CONTENTS = {
    ["0123456789abcde"].then { _1 * 33 }.join("/") => {size: 496, mode: 0o644},
    "endfile" => {size: 0, mode: 0o644}
  }

  def test_each_works
    Minitar::Input.open(open_fixture("issue_46")) do |stream|
      outer = 0
      stream.each.with_index do |entry, i|
        assert_kind_of Minitar::Reader::EntryStream, entry
        assert SUPERLONG_CONTENTS.key?(entry.name), "File #{entry.name} not defined"

        assert_equal SUPERLONG_CONTENTS[entry.name][:size],
          entry.size, "File sizes sizes do not match: #{entry.name}"

        assert_modes_equal(SUPERLONG_CONTENTS[entry.name][:mode],
          entry.mode, entry.name)
        assert_equal TIME_2004, entry.mtime, "entry.mtime"

        outer += 1
      end

      assert_equal 2, outer
    end
  end
end
