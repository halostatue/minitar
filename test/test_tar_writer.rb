#!/usr/bin/env ruby

require 'minitar'
require 'minitest_helper'

class TestTarWriter < Minitest::Test
  class DummyIO
    attr_reader :data

    def initialize
      @data = ""
    end

    def write(dat)
      data << dat
      dat.size
    end

    def reset
      @data = ""
    end
  end

  def setup
    @data = "a" * 10
    @dummyos = DummyIO.new
    @os = Minitar::Writer.new(@dummyos)
  end

  def teardown
    @os.close
  end

  def test_add_file_simple
    @dummyos.reset

    Minitar::Writer.open(@dummyos) do |os|
      os.add_file_simple("lib/foo/bar", :mode => 0644, :size => 10) do |f|
        f.write "a" * 10
      end
      os.add_file_simple("lib/bar/baz", :mode => 0644, :size => 100) do |f|
        f.write "fillme"
      end
    end

    assert_headers_equal(tar_file_header("lib/foo/bar", "", 0644, 10),
                         @dummyos.data[0, 512])
    assert_equal("a" * 10 + "\0" * 502, @dummyos.data[512, 512])
    assert_headers_equal(tar_file_header("lib/bar/baz", "", 0644, 100),
                        @dummyos.data[512 * 2, 512])
    assert_equal("fillme" + "\0" * 506, @dummyos.data[512 * 3, 512])
    assert_equal("\0" * 512, @dummyos.data[512 * 4, 512])
    assert_equal("\0" * 512, @dummyos.data[512 * 5, 512])
  end

  def test_write_operations_fail_after_closed
    @dummyos.reset
    @os.add_file_simple("sadd", :mode => 0644, :size => 20) { |f| }
    @os.close
    assert_raises(Minitar::ClosedStream) { @os.flush }
    assert_raises(Minitar::ClosedStream) { @os.add_file("dfdsf", :mode => 0644) {} }
    assert_raises(Minitar::ClosedStream) { @os.mkdir "sdfdsf", :mode => 0644 }
  end

  def test_file_name_is_split_correctly
      # test insane file lengths, and: a{100}/b{155}, etc
    @dummyos.reset
    names = [ "#{'a' * 155}/#{'b' * 100}", "#{'a' * 151}/#{'qwer/' * 19}bla" ]
    o_names = [ "#{'b' * 100}", "#{'qwer/' * 19}bla" ]
    o_prefixes = [ "a" * 155, "a" * 151 ]
    names.each do |name|
      @os.add_file_simple(name, :mode => 0644, :size => 10) { }
    end
    o_names.each_with_index do |nam, i|
      assert_headers_equal(tar_file_header(nam, o_prefixes[i], 0644, 10),
                           @dummyos.data[2 * i * 512, 512])
    end
    assert_raises(Minitar::FileNameTooLong) do
      @os.add_file_simple(File.join("a" * 152, "b" * 10, "a" * 92),
                                    :mode => 0644, :size => 10) { }
    end
    assert_raises(Minitar::FileNameTooLong) do
      @os.add_file_simple(File.join("a" * 162, "b" * 10),
                                    :mode => 0644, :size => 10) { }
    end
    assert_raises(Minitar::FileNameTooLong) do
      @os.add_file_simple(File.join("a" * 10, "b" * 110),
                                    :mode => 0644, :size => 10) { }
    end
    # Issue #6.
    assert_raises(Minitar::FileNameTooLong) do
      @os.add_file_simple("a" * 114, :mode => 0644, :size => 10) { }
    end
  end

  def test_add_file
    dummyos = StringIO.new
    class << dummyos
      def method_missing(meth, *a)
        self.string.send(meth, *a)
      end
    end
    content1 = ('a'..'z').to_a.join("")  # 26
    content2 = ('aa'..'zz').to_a.join("") # 1352
    Minitar::Writer.open(dummyos) do |os|
      os.add_file("lib/foo/bar", :mode => 0644) { |f, opts| f.write "a" * 10 }
      os.add_file("lib/bar/baz", :mode => 0644) { |f, opts| f.write content1 }
      os.add_file("lib/bar/baz", :mode => 0644) { |f, opts| f.write content2 }
      os.add_file("lib/bar/baz", :mode => 0644) { |f, opts| }
    end
    assert_headers_equal(tar_file_header("lib/foo/bar", "", 0644, 10),
                         dummyos[0, 512])
    assert_equal(%Q(#{"a" * 10}#{"\0" * 502}), dummyos[512, 512])
    offset = 512 * 2
    [content1, content2, ""].each do |data|
      assert_headers_equal(tar_file_header("lib/bar/baz", "", 0644,
                                          data.size), dummyos[offset, 512])
      offset += 512
      until !data || data == ""
        chunk = data[0, 512]
        data[0, 512] = ""
        assert_equal(chunk + "\0" * (512 - chunk.size),
        dummyos[offset, 512])
        offset += 512
      end
    end
    assert_equal("\0" * 1024, dummyos[offset, 1024])
  end

  def test_add_file_tests_seekability
    assert_raises(Archive::Tar::Minitar::NonSeekableStream) do
      @os.add_file("libdfdsfd", :mode => 0644) { |f| }
    end
  end

  def test_write_header
    @dummyos.reset
    @os.add_file_simple("lib/foo/bar", :mode => 0644, :size => 0) { |f|  }
    @os.flush
    assert_headers_equal(tar_file_header("lib/foo/bar", "", 0644, 0),
                        @dummyos.data[0, 512])
    @dummyos.reset
    @os.mkdir("lib/foo", :mode => 0644)
    assert_headers_equal(tar_dir_header("lib/foo", "", 0644),
                        @dummyos.data[0, 512])
    @os.mkdir("lib/bar", :mode => 0644)
    assert_headers_equal(tar_dir_header("lib/bar", "", 0644),
                        @dummyos.data[512 * 1, 512])
  end

  def test_write_data
    @dummyos.reset
    @os.add_file_simple("lib/foo/bar", :mode => 0644, :size => 10) do |f|
      f.write @data
    end
    @os.flush
    assert_equal(@data + ("\0" * (512-@data.size)),
    @dummyos.data[512, 512])
  end

  def test_file_size_is_checked
    @dummyos.reset
    assert_raises(Minitar::Writer::WriteBoundaryOverflow) do
      @os.add_file_simple("lib/foo/bar", :mode => 0644, :size => 10) do |f|
        f.write "1" * 100
      end
    end
    @os.add_file_simple("lib/foo/bar", :mode => 0644, :size => 10) {|f| }
  end
end
