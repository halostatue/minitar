#!/usr/bin/env ruby

require "minitar"
require "minitest_helper"

class TestTarReader < Minitest::Test
  def test_open_no_block
    str = tar_file_header("lib/foo", "", 0o10644, 10) + "\0" * 512
    str += tar_file_header("bar", "baz", 0o644, 0)
    str += tar_dir_header("foo", "bar", 0o12345)
    str += "\0" * 1024

    reader = Minitar::Reader.open(StringIO.new(str))
    refute reader.closed?
  ensure
    reader.close
    refute reader.closed? # Reader doesn't actually close anything
  end

  def test_multiple_entries
    str = tar_file_header("lib/foo", "", 0o10644, 10) + "\0" * 512
    str += tar_file_header("bar", "baz", 0o644, 0)
    str += tar_dir_header("foo", "bar", 0o12345)
    str += tar_file_header("src/", "", 0o755, 0) # "file" with a trailing slash
    str += "\0" * 1024
    names = %w[lib/foo bar foo src/]
    prefixes = ["", "baz", "bar", ""]
    modes = [0o10644, 0o644, 0o12345, 0o755]
    sizes = [10, 0, 0, 0]
    isdir = [false, false, true, true]
    isfile = [true, true, false, false]
    Minitar::Reader.new(StringIO.new(str)) do |is|
      i = 0
      is.each_entry do |entry|
        assert_kind_of Minitar::Reader::EntryStream, entry
        assert_equal names[i], entry.name
        assert_equal prefixes[i], entry.prefix
        assert_equal sizes[i], entry.size
        assert_equal modes[i], entry.mode
        assert_equal isdir[i], entry.directory?
        assert_equal isfile[i], entry.file?
        if prefixes[i] != ""
          assert_equal File.join(prefixes[i], names[i]), entry.full_name
        else
          assert_equal names[i], entry.name
        end
        i += 1
      end
      assert_equal names.size, i
    end
  end

  def test_rewind_entry_works
    content = ("a".."z").to_a.join(" ")
    str = tar_file_header("lib/foo", "", 0o10644, content.bytesize) +
      content + "\0" * (512 - content.bytesize)
    str << "\0" * 1024
    Minitar::Reader.new(StringIO.new(str)) do |is|
      is.each_entry do |entry|
        3.times do
          entry.rewind
          assert_equal content, entry.read
          assert_equal content.bytesize, entry.pos
        end
      end
    end
  end

  def test_rewind_works
    content = ("a".."z").to_a.join(" ")
    str = tar_file_header("lib/foo", "", 0o10644, content.bytesize) +
      content + "\0" * (512 - content.bytesize)
    str << "\0" * 1024
    Minitar::Reader.new(StringIO.new(str)) do |is|
      3.times do
        is.rewind
        i = 0
        is.each_entry do |entry|
          assert_equal content, entry.read
          i += 1
        end
        assert_equal 1, i
      end
    end
  end

  def test_read_works
    contents = ("a".."z").inject("") { |a, e| a << e * 100 }
    str = tar_file_header("lib/foo", "", 0o10644, contents.bytesize) + contents
    str += "\0" * (512 - (str.bytesize % 512))
    Minitar::Reader.new(StringIO.new(str)) do |is|
      is.each_entry do |entry|
        assert_kind_of Minitar::Reader::EntryStream, entry
        data = entry.read(3000) # bigger than contents.bytesize
        assert_equal contents, data
        assert entry.eof?
      end
    end
    Minitar::Reader.new(StringIO.new(str)) do |is|
      is.each_entry do |entry|
        assert_kind_of Minitar::Reader::EntryStream, entry
        data = entry.read(100)
        (entry.size - data.bytesize).times { data << entry.getc.chr }
        assert_equal contents, data
        assert_nil entry.read(10)
        assert entry.eof?
      end
    end
    Minitar::Reader.new(StringIO.new(str)) do |is|
      is.each_entry do |entry|
        assert_kind_of Minitar::Reader::EntryStream, entry
        data = entry.read
        assert_equal contents, data
        assert_nil entry.read(10)
        assert_nil entry.read
        assert_nil entry.getc
        assert entry.eof?
      end
    end
  end

  def test_eof_works
    str = tar_file_header("bar", "baz", 0o644, 0)
    Minitar::Reader.new(StringIO.new(str)) do |is|
      is.each_entry do |entry|
        assert_kind_of Minitar::Reader::EntryStream, entry
        data = entry.read
        assert_nil data
        assert_nil entry.read(10)
        assert_nil entry.read
        assert_nil entry.getc
        assert entry.eof?
      end
    end
    str = tar_dir_header("foo", "bar", 0o12345)
    Minitar::Reader.new(StringIO.new(str)) do |is|
      is.each_entry do |entry|
        assert_kind_of Minitar::Reader::EntryStream, entry
        data = entry.read
        assert_nil data
        assert_nil entry.read(10)
        assert_nil entry.read
        assert_nil entry.getc
        assert entry.eof?
      end
    end
    str = tar_dir_header("foo", "bar", 0o12345)
    str += tar_file_header("bar", "baz", 0o644, 0)
    str += tar_file_header("bar", "baz", 0o644, 0)
    Minitar::Reader.new(StringIO.new(str)) do |is|
      is.each_entry do |entry|
        assert_kind_of Minitar::Reader::EntryStream, entry
        data = entry.read
        assert_nil data
        assert_nil entry.read(10)
        assert_nil entry.read
        assert_nil entry.getc
        assert entry.eof?
      end
    end
  end

  def test_read_invalid_tar_file
    assert_raises Minitar::InvalidTarStream do
      Minitar::Reader.open(StringIO.new("testing")) do |r|
        r.each_entry do |entry|
          fail "invalid tar file should not read files"
        end
      end
    end
  end
end
