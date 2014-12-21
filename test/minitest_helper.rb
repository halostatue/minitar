# -*- ruby encoding: utf-8 -*-

require 'fileutils'

gem 'minitest'
require 'minitest/autorun'

module TarTester
  private
  def assert_headers_equal(h1, h2)
    fields = %w(name 100 mode 8 uid 8 gid 8 size 12 mtime 12 checksum 8
                typeflag 1 linkname 100 magic 6 version 2 uname 32 gname 32
                devmajor 8 devminor 8 prefix 155)
    offset = 0
    until fields.empty?
      name = fields.shift
      length = fields.shift.to_i
      if name == "checksum"
        chksum_off = offset
        offset += length
        next
      end
      assert_equal(h1[offset, length], h2[offset, length],
                   "Field #{name} of the tar header differs.")
      offset += length
    end
    assert_equal(h1[chksum_off, 8], h2[chksum_off, 8], "Checksumes differ.")
  end

  def assert_modes_equal(expected, actual, name)
    unless RUBY_PLATFORM =~ /win32/
      expected = "%04o" % (expected & 0777)
      actual = "%04o" % (actual & 0777)

      assert_equal(expected, actual, "Mode for #{name} does not match")
    end
  end

  def tar_file_header(fname, dname, mode, length)
    h = header("0", fname, dname, length, mode)
    checksum = calc_checksum(h)
    header("0", fname, dname, length, mode, checksum)
  end

  def tar_dir_header(name, prefix, mode)
    h = header("5", name, prefix, 0, mode)
    checksum = calc_checksum(h)
    header("5", name, prefix, 0, mode, checksum)
  end

  def header(type, fname, dname, length, mode, checksum = nil)
    checksum ||= " " * 8
    arr = [ASCIIZ(fname, 100), Z(to_oct(mode, 7)), Z(to_oct(nil, 7)),
           Z(to_oct(nil, 7)), Z(to_oct(length, 11)), Z(to_oct(0, 11)),
           checksum, type, "\0" * 100, "ustar\0", "00", ASCIIZ("", 32),
           ASCIIZ("", 32), Z(to_oct(nil, 7)), Z(to_oct(nil, 7)),
           ASCIIZ(dname, 155) ]
    arr = arr.join.bytes.to_a
    h = arr.pack("C100C8C8C8C12C12C8CC100C6C2C32C32C8C8C155")
    ret = h + "\0" * (512 - h.size)
    assert_equal(512, ret.size)
    ret
  end

  def calc_checksum(header)
    sum = header.unpack("C*").inject { |s, a| s + a }
    SP(Z(to_oct(sum, 6)))
  end

  def to_oct(n, pad_size)
    if n.nil?
      "\0" * pad_size
    else
      "%0#{pad_size}o" % n
    end
  end

  def ASCIIZ(str, length)
    str + "\0" * (length - str.length)
  end

  def SP(s)
    s + " "
  end

  def Z(s)
    s + "\0"
  end

  def SP_Z(s)
    s + " \0"
  end
end
