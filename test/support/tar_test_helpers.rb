# frozen_string_literal: true

module TarTestHelpers
  private

  module Constants
    FIELDS = {
      'name' => 100,
      'mode' => 8,
      'uid' => 8,
      'gid' => 8,
      'size' => 12,
      'mtime' => 12,
      'checksum' => 8,
      'typeflag' => 1,
      'linkname' => 100,
      'magic' => 6,
      'version' => 2,
      'uname' => 32,
      'gname' => 32,
      'devmajor' => 8,
      'devminor' => 8,
      'prefix' => 155
    }

    BLANK_CHECKSUM = " " * 8
    CHECKSUM_OFFSET = FIELDS.keys.inject(0) { |length, field|
      break length if field == 'checksum'
      length + FIELDS[field]
    }

    NULL_100 = "\0" * 100
    USTAR = "ustar\0"
    DOUBLE_ZERO = "00"
  end

  def assert_headers_equal(expected, actual)
    offset = 0
    Constants::FIELDS.each do |field, length|
      message = if field == 'checksum'
                  "Header checksums are expected to match."
                else
                  "Header field #{field} is expected to match."
                end

      assert_equal(expected[offset, length], actual[offset, length], message)

      offset += length
    end
  end

  def assert_modes_equal(expected, actual, name)
    return if Minitar.windows?

    assert_equal(
      mode_string(expected),
      mode_string(actual),
      "Mode for #{name} does not match"
    )
  end

  def tar_file_header(fname, dname, mode, length)
    update_checksum(header("0", fname, dname, length, mode))
  end

  def tar_dir_header(name, prefix, mode)
    update_checksum(header("5", name, prefix, 0, mode))
  end

  def header(type, fname, dname, length, mode)
    checksum ||= Constants::BLANK_CHECKSUM
    arr = [
      asciiz(fname, 100), z(to_oct(mode, 7)), z(to_oct(nil, 7)),
      z(to_oct(nil, 7)), z(to_oct(length, 11)), z(to_oct(0, 11)),
      Constants::BLANK_CHECKSUM, type, Constants::NULL_100, Constants::USTAR,
      Constants::DOUBLE_ZERO, asciiz("", 32), asciiz("", 32),
      z(to_oct(nil, 7)), z(to_oct(nil, 7)), asciiz(dname, 155)
    ]
    h = arr.join.bytes.to_a.pack("C100C8C8C8C12C12C8CC100C6C2C32C32C8C8C155")
    ret = h + "\0" * (512 - h.size)
    assert_equal(512, ret.size)
    ret
  end

  def update_checksum(header)
    header[Constants::CHECKSUM_OFFSET, Constants::FIELDS['checksum']] =
      # inject(:+) was introduced in which version?
      sp(z(to_oct(header.unpack("C*").inject { |s, a| s + a }, 6)))
    header
  end

  def to_oct(n, pad_size)
    if n.nil?
      "\0" * pad_size
    else
      "%0#{pad_size}o" % n
    end
  end

  def asciiz(str, length)
    str + "\0" * (length - str.length)
  end

  def sp(s)
    s + " "
  end

  def z(s)
    s + "\0"
  end

  def mode_string(value)
    "%04o" % (value & 0777)
  end

  Minitest::Test.send(:include, self)
end
