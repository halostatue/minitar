# frozen_string_literal: true

require "minitest_helper"

class TestTarWriter < Minitest::Test
  class DummyIO
    attr_reader :data

    def initialize
      reset
    end

    def write(dat)
      data << dat
      dat.size
    end

    def reset
      @data = +""
      @data.force_encoding("ascii-8bit")
    end
  end

  def setup
    @data = "a" * 10
    @unicode = [0xc3.chr, 0xa5.chr].join * 10
    @unicode.force_encoding("utf-8")
    @dummy_writer = DummyIO.new
    @writer = Minitar::Writer.new(@dummy_writer)
  end

  def teardown
    @writer.close
  end

  def test_open_no_block
    writer = Minitar::Writer.open(@dummy_writer)
    refute writer.closed?
  ensure
    writer.close
    assert writer.closed?
  end

  def test_add_file_simple
    Minitar::Writer.open(@dummy_writer) do |os|
      os.add_file_simple("lib/foo/bar", mode: 0o644, size: 10) { _1.write "a" * 10 }
      os.add_file_simple("lib/bar/baz", mode: 0o644, size: 100) { _1.write "fillme" }
    end

    assert_headers_equal build_tar_file_header("lib/foo/bar", "", 0o644, 10),
      @dummy_writer.data[0, 512]

    assert_equal "a" * 10 + "\0" * 502, @dummy_writer.data[512, 512]

    assert_headers_equal build_tar_file_header("lib/bar/baz", "", 0o644, 100),
      @dummy_writer.data[512 * 2, 512]

    assert_equal "fillme" + "\0" * 506, @dummy_writer.data[512 * 3, 512]
    assert_equal "\0" * 512, @dummy_writer.data[512 * 4, 512]
    assert_equal "\0" * 512, @dummy_writer.data[512 * 5, 512]
  end

  def test_write_operations_fail_after_closed
    @writer.add_file_simple("sadd", mode: 0o644, size: 20) {}
    @writer.close
    assert_raises(Minitar::ClosedStream) { @writer.flush }
    assert_raises(Minitar::ClosedStream) { @writer.add_file("dfdsf", mode: 0o644) {} }
    assert_raises(Minitar::ClosedStream) { @writer.mkdir "sdfdsf", mode: 0o644 }
    assert_raises(Minitar::ClosedStream) { @writer.symlink "a", "b", mode: 0o644 }
  end

  def test_file_name_is_split_correctly
    # test extreme file lengths, and: a{100}/b{155}, etc
    names = {
      "#{"a" * 155}/#{"b" * 100}" => {name: "b" * 100, prefix: "a" * 155},
      "#{"a" * 151}/#{"qwer/" * 19}bla" => {name: "#{"qwer/" * 19}bla", prefix: "a" * 151},
      "/#{"a" * 49}/#{"b" * 50}" => {name: "b" * 50, prefix: "/#{"a" * 49}"},
      "#{"a" * 49}/#{"b" * 50}x" => {name: "#{"b" * 50}x", prefix: "a" * 49},
      "#{"a" * 49}x/#{"b" * 50}" => {name: "b" * 50, prefix: "#{"a" * 49}x"}
    }

    names.each_key do |name|
      @writer.add_file_simple(name, mode: 0o644, size: 10) {}
    end

    names.each_key.with_index do |key, index|
      name, prefix = names[key][:name], names[key][:prefix]

      assert_headers_equal build_tar_file_header(name, prefix, 0o644, 10),
        @dummy_writer.data[2 * index * 512, 512]
    end
  end

  def test_file_name_is_long
    @writer.add_file_simple(File.join("a" * 152, "b" * 10, "c" * 92), mode: 0o644, size: 10) {}
    @writer.add_file_simple(File.join("d" * 162, "e" * 10), mode: 0o644, size: 10) {}
    @writer.add_file_simple(File.join("f" * 10, "g" * 110), mode: 0o644, size: 10) {}
    # Issue #6.
    @writer.add_file_simple("a" * 114, mode: 0o644, size: 10) {}

    # "././@LongLink", a file name, its actual header, its data, ...
    4.times do |i|
      assert_equal Minitar::PosixHeader::GNU_EXT_LONG_LINK,
        @dummy_writer.data[4 * i * 512, 32].rstrip
    end
  end

  def test_add_file_simple_content_with_long_name
    long_name_file_content = "where_is_all_the_content_gone"

    @writer.add_file_simple("a" * 114, mode: 0o0644, data: long_name_file_content)

    assert_equal long_name_file_content,
      @dummy_writer.data[3 * 512, long_name_file_content.bytesize]
  end

  def test_add_file_content_with_long_name
    dummyos = StringIO.new
    def dummyos.method_missing(meth, *a)
      string.send(meth, *a)
    end

    def dummyos.respond_to_missing?(meth, all)
      string.respond_to?(meth, all)
    end

    long_name_file_content = "where_is_all_the_content_gone"

    Minitar::Writer.open(dummyos) do |os|
      os.add_file("a" * 114, mode: 0o0644) do |f|
        f.write(long_name_file_content)
      end
    end

    assert_equal long_name_file_content,
      dummyos[3 * 512, long_name_file_content.bytesize]
  end

  def test_add_file
    dummyos = StringIO.new
    def dummyos.method_missing(meth, *a)
      string.send(meth, *a)
    end

    def dummyos.respond_to_missing?(meth, all)
      string.respond_to?(meth, all)
    end

    content1 = ("a".."z").to_a.join("") # 26
    content2 = ("aa".."zz").to_a.join("") # 1352

    Minitar::Writer.open(dummyos) do |os|
      os.add_file("lib/foo/bar", mode: 0o644) { |f, _opts| f.write "a" * 10 }
      os.add_file("lib/bar/baz", mode: 0o644) { |f, _opts| f.write content1 }
      os.add_file("lib/bar/baz", mode: 0o644) { |f, _opts| f.write content2 }
      os.add_file("lib/bar/baz", mode: 0o644) { |_f, _opts| }
    end

    assert_headers_equal build_tar_file_header("lib/foo/bar", "", 0o644, 10),
      dummyos[0, 512]

    assert_equal %(#{"a" * 10}#{"\0" * 502}), dummyos[512, 512]
    offset = 512 * 2

    [content1, content2, ""].each do |data|
      assert_headers_equal build_tar_file_header("lib/bar/baz", "", 0o644, data.bytesize),
        dummyos[offset, 512]

      offset += 512

      until !data || data == ""
        chunk = data[0, 512]
        data[0, 512] = ""

        assert_equal chunk + "\0" * (512 - chunk.bytesize), dummyos[offset, 512]
        offset += 512
      end
    end

    assert_equal "\0" * 1024, dummyos[offset, 1024]
  end

  def test_add_file_tests_seekability
    assert_raises(Minitar::NonSeekableStream) do
      @writer.add_file("libdfdsfd", mode: 0o644) { |f| }
    end
  end

  def test_write_header
    @writer.add_file_simple("lib/foo/bar", mode: 0o644, size: 0) {}
    @writer.flush

    assert_headers_equal build_tar_file_header("lib/foo/bar", "", 0o644, 0),
      @dummy_writer.data[0, 512]

    @dummy_writer.reset
    @writer.mkdir("lib/foo", mode: 0o644)

    assert_headers_equal build_tar_dir_header("lib/foo", "", 0o644),
      @dummy_writer.data[0, 512]

    @writer.mkdir("lib/bar", mode: 0o644)

    assert_headers_equal build_tar_dir_header("lib/bar", "", 0o644),
      @dummy_writer.data[512 * 1, 512]
  end

  def test_write_data
    @writer.add_file_simple("lib/foo/bar", mode: 0o644, size: 10) do |f|
      f.write @data
    end
    @writer.flush

    assert_equal @data + ("\0" * (512 - @data.bytesize)), @dummy_writer.data[512, 512]
  end

  def test_write_unicode_data
    assert_equal 10, @unicode.size
    assert_equal 20, @unicode.bytesize
    @unicode.force_encoding("ascii-8bit")

    file = ["lib/foo/b", 0xc3.chr, 0xa5.chr, "r"].join

    @writer.add_file_simple(file, mode: 0o644, size: 20) do |f|
      f.write @unicode
    end
    @writer.flush

    assert_equal @unicode + ("\0" * (512 - @unicode.bytesize)), @dummy_writer.data[512, 512]
  end

  def test_file_size_is_checked
    assert_raises(Minitar::Writer::WriteBoundaryOverflow) do
      @writer.add_file_simple("lib/foo/bar", mode: 0o644, size: 10) do |f|
        f.write "1" * 100
      end
    end
    @writer.add_file_simple("lib/foo/bar", mode: 0o644, size: 10) { |f| }
  end

  def test_symlink
    @writer.symlink("lib/foo/bar", "lib/foo/baz", mode: 0o644)
    @writer.flush
    assert_headers_equal build_tar_symlink_header("lib/foo/bar", "", 0o644, "lib/foo/baz"),
      @dummy_writer.data[0, 512]
  end

  def test_symlink_target_size_is_checked
    assert_raises(Minitar::FileNameTooLong) do
      @writer.symlink("lib/foo/bar", "x" * 101)
    end
  end
end
