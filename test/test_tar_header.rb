#!/usr/bin/env ruby

require 'archive/tar/minitar'
require 'minitest_helper'

class TestTarHeader < Minitest::Test
  include TarTester

  def test_arguments_are_checked
    assert_raises(ArgumentError) {
      Archive::Tar::Minitar::PosixHeader.new(:name => "", :size => "", :mode => "")
    }
    assert_raises(ArgumentError) {
      Archive::Tar::Minitar::PosixHeader.new(:name => "", :size => "", :prefix => "")
    }
    assert_raises(ArgumentError) {
      Archive::Tar::Minitar::PosixHeader.new(:name => "", :prefix => "", :mode => "")
    }
    assert_raises(ArgumentError) {
      Archive::Tar::Minitar::PosixHeader.new(:prefix => "", :size => "", :mode => "")
    }
  end

  def test_basic_headers
    header = {
      :name => "bla",
      :mode => 012345,
      :size => 10,
      :prefix => "",
      :typeflag => "0"
    }
    assert_headers_equal(tar_file_header("bla", "", 012345, 10),
                         Archive::Tar::Minitar::PosixHeader.new(header).to_s)

    header = {
      :name => "bla",
      :mode => 012345,
      :size => 0,
      :prefix => "",
      :typeflag => "5"
    }
    assert_headers_equal(tar_dir_header("bla", "", 012345),
                         Archive::Tar::Minitar::PosixHeader.new(header).to_s)
  end

  def test_long_name_works
    header = { :name => "a" * 100, :mode => 012345, :size => 10, :prefix => "" }
    assert_headers_equal(tar_file_header("a" * 100, "", 012345, 10),
                         Archive::Tar::Minitar::PosixHeader.new(header).to_s)
    header = { :name => "a" * 100, :mode => 012345, :size => 10, :prefix => "bb" * 60 }
    assert_headers_equal(tar_file_header("a" * 100, "bb" * 60, 012345, 10),
                         Archive::Tar::Minitar::PosixHeader.new(header).to_s)
  end

  def test_new_from_stream
    header = tar_file_header("a" * 100, "", 012345, 10)
    header = StringIO.new(header)
    h = Archive::Tar::Minitar::PosixHeader.new_from_stream(header)
    assert_equal("a" * 100, h.name)
    assert_equal(012345, h.mode)
    assert_equal(10, h.size)
    assert_equal("", h.prefix)
    assert_equal("ustar", h.magic)
  end

  def test_new_from_stream_with_evil_name
    header = tar_file_header("a \0" + "\0" * 97, "", 012345, 10)
    header = StringIO.new(header)
    h = Archive::Tar::Minitar::PosixHeader.new_from_stream header
    assert_equal("a ", h.name)
  end
end
