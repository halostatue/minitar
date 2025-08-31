# frozen_string_literal: true

# Test assertions and helpers for working with header objects.
module Minitar::TestHelpers::Header
  private

  # Assert that the +actual+ header is equal to +expected+.
  def assert_headers_equal(expected, actual)
    actual = actual.to_s
    __field_order.each do |field|
      message =
        if field == "checksum"
          "Header checksums are expected to match."
        else
          "Header field #{field} is expected to match."
        end

      offset = __fields[field].offset
      length = __fields[field].length

      assert_equal expected[offset, length], actual[offset, length], message
    end
  end

  def assert_modes_equal(expected, actual, name)
    return if Minitar.windows?

    assert_equal mode_string(expected), mode_string(actual), "Mode for #{name} does not match"
  end

  def build_raw_header(type, fname, dname, length, mode, link_name = "") =
    [
      fname, mode, z(octal(nil, 7)), z(octal(nil, 7)), length, z(octal(0, 11)),
      BLANK_CHECKSUM, type, asciiz(link_name, 100), USTAR, DOUBLE_ZERO, asciiz("", 32),
      asciiz("", 32), z(octal(nil, 7)), z(octal(nil, 7)), dname
    ].join.bytes.to_a.pack("C100C8C8C8C12C12C8CC100C6C2C32C32C8C8C155").then {
      "#{_1}#{"\0" * (512 - _1.bytesize)}"
    }.tap { assert_equal 512, _1.bytesize }

  def build_header(type, fname, dname, length, mode, link_name = "") =
    build_raw_header(
      type,
      asciiz(fname, 100),
      asciiz(dname, 155),
      z(octal(length, 11)),
      z(octal(mode, 7)),
      asciiz(link_name, 100)
    )

  def build_tar_file_header(fname, dname, mode, length) =
    build_header("0", fname, dname, length, mode).then {
      update_header_checksum(_1)
    }

  def build_tar_dir_header(name, prefix, mode) =
    build_header("5", name, prefix, 0, mode).then {
      update_header_checksum(_1)
    }

  def build_tar_symlink_header(name, prefix, mode, target) =
    build_header("2", name, prefix, 0, mode, target).then {
      update_header_checksum(_1)
    }

  def build_tar_pax_header(name, prefix, content_size) =
    build_header("x", name, prefix, content_size, 0o644).then {
      update_header_checksum(_1)
    }

  def update_header_checksum(header) =
    header.tap { |h|
      checksum = __fields["checksum"]
      h[checksum.offset, checksum.length] =
        h.unpack("C*")
          .inject(:+)
          .then { octal(_1, 6) }
          .then { z(_1) }
          .then { sp(_1) }
    }

  def octal(n, pad_size) = n.nil? ? "\0" * pad_size : "%0#{pad_size}o" % n

  def asciiz(str, length) = "#{str}#{"\0" * (length - str.bytesize)}"

  def sp(s) = "#{s} "

  def z(s) = "#{s}\0"

  def mode_string(value) = "%04o" % (value & 0o777)

  def __field_order = FIELD_ORDER

  def __fields = FIELDS

  FIELD_ORDER = []
  private_constant :FIELD_ORDER

  FIELDS = {}
  private_constant :FIELDS

  Field = Struct.new(:name, :offset, :length)
  private_constant :Field

  BLANK_CHECKSUM = (" " * 8).freeze
  private_constant :BLANK_CHECKSUM

  DOUBLE_ZERO = "00"
  private_constant :DOUBLE_ZERO

  NULL_100 = ("\0" * 100).freeze
  private_constant :NULL_100

  USTAR = "ustar\0"
  private_constant :USTAR

  fields = [
    ["name", 100], ["mode", 8], ["uid", 8], ["gid", 8], ["size", 12], ["mtime", 12],
    ["checksum", 8], ["typeflag", 1], ["linkname", 100], ["magic", 6], ["version", 2],
    ["uname", 32], ["gname", 32], ["devmajor", 8], ["devminor", 8], ["prefix", 155]
  ]
  offset = 0

  fields.each do |(name, length)|
    FIELDS[name] = Field.new(name, offset, length)
    FIELD_ORDER << name
    offset += length
  end

  Minitest::Test.send(:include, self)
end
