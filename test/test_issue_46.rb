#!/usr/bin/env ruby

require "minitar"
require "minitest_helper"
require "base64"
require "zlib"

class TestIssue46 < Minitest::Test
  SUPERLONG_TGZ = Base64.decode64(<<~EOS).freeze
    H4sIAK1+smYAA+3WQQ6CMBAF0K49BScAprYd3XkALoECSiQlQYzXt0IkSKLGBdXE
    /zbtNF000PkQRmG0SWq7T0p7FPOIHaNUNzrTkWI5zPt1IiYtgmSm8zw4n9q0CQLR
    1HX7at/lkOeVjwP5FZNcKm14tU63uyyPUP91/e3rCJ75uF/j/Gej+6yXw/fArbnM
    Z2ZlDKlb/ktNrEQQ+3gA9/xP3aS0z/e5bUXh40B+/Vj+oJ63Xkzff26zoqzmzf13
    /d/98437n0izQf8DAAAAAAAAAAAAAAAAAHziCqQuXDYAKAAA
  EOS

  FILETIMES = Time.utc(2004).to_i

  superlong_name = (["0123456789abcde"] * 33).join("/")

  SUPERLONG_CONTENTS = {
    superlong_name => {size: 496, mode: 0o644},
    "endfile" => {size: 0, mode: 0o644}
  }

  def test_each_works
    reader = Zlib::GzipReader.new(StringIO.new(SUPERLONG_TGZ))

    Minitar::Input.open(reader) do |stream|
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
