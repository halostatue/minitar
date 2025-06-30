require "minitest_helper"

class TestTarHeader < Minitest::Test
  def test_arguments_are_checked
    ph = Minitar::PosixHeader
    assert_raises(ArgumentError) {
      ph.new(name: "", size: "", mode: "")
    }
    assert_raises(ArgumentError) {
      ph.new(name: "", size: "", prefix: "")
    }
    assert_raises(ArgumentError) {
      ph.new(name: "", prefix: "", mode: "")
    }
    assert_raises(ArgumentError) {
      ph.new(prefix: "", size: "", mode: "")
    }
  end

  def test_basic_headers
    header = {
      name: "bla",
      mode: 0o12345,
      size: 10,
      prefix: "",
      typeflag: "0"
    }
    assert_headers_equal(tar_file_header("bla", "", 0o12345, 10),
      Minitar::PosixHeader.new(header).to_s)

    header = {
      name: "bla",
      mode: 0o12345,
      size: 0,
      prefix: "",
      typeflag: "5"
    }
    assert_headers_equal(tar_dir_header("bla", "", 0o12345),
      Minitar::PosixHeader.new(header).to_s)
  end

  def test_long_name_works
    header = {
      name: "a" * 100, mode: 0o12345, size: 10, prefix: ""
    }
    assert_headers_equal(tar_file_header("a" * 100, "", 0o12345, 10),
      Minitar::PosixHeader.new(header).to_s)
    header = {
      name: "a" * 100, mode: 0o12345, size: 10, prefix: "bb" * 60
    }
    assert_headers_equal(tar_file_header("a" * 100, "bb" * 60, 0o12345, 10),
      Minitar::PosixHeader.new(header).to_s)
  end

  def test_from_stream
    header = tar_file_header("a" * 100, "", 0o12345, 10)
    header = StringIO.new(header)
    h = Minitar::PosixHeader.from_stream(header)
    assert_equal "a" * 100, h.name
    assert_equal 0o12345, h.mode
    assert_equal 10, h.size
    assert_equal "", h.prefix
    assert_equal "ustar", h.magic
  end

  def test_from_stream_with_evil_name
    header = tar_file_header("a \0" + "\0" * 97, "", 0o12345, 10)
    header = StringIO.new(header)
    h = Minitar::PosixHeader.from_stream header
    assert_equal "a ", h.name
  end

  def test_valid_with_valid_header
    header = tar_file_header("a" * 100, "", 0o12345, 10)
    header = StringIO.new(header)
    h = Minitar::PosixHeader.from_stream header

    assert(h.valid?)
  end

  def test_from_stream_with_no_strict_octal
    header = tar_file_header("a" * 100, "", 0o12345, -1213)
    io = StringIO.new(header)

    assert_raises(ArgumentError) do
      Minitar::PosixHeader.from_stream(io)
    end
  end

  def test_from_stream_with_octal_wrapped_by_spaces
    header = raw_header(0,
      asciiz("a" * 100, 100),
      asciiz("", 155),
      "       1213\0",
      z(to_oct(0o12345, 7)))

    header = update_checksum(header)
    io = StringIO.new(header)
    header = Minitar::PosixHeader.from_stream(io)

    assert_equal 651, header.size
  end

  def test_valid_with_invalid_header
    header = StringIO.new("testing")
    h = Minitar::PosixHeader.from_stream header

    refute(h.valid?)
  end

  def test_parse_numeric_field_octal
    ph = Minitar::PosixHeader
    assert_equal 123, ph.send(:parse_numeric_field, "173")
    assert_equal 0, ph.send(:parse_numeric_field, "0")
    assert_equal 511, ph.send(:parse_numeric_field, "777")
  end

  def test_parse_numeric_field_octal_with_spaces
    ph = Minitar::PosixHeader
    assert_equal 123, ph.send(:parse_numeric_field, "  173  ")
    assert_equal 0, ph.send(:parse_numeric_field, "       ")
  end

  def test_parse_numeric_field_binary_positive_number
    binary_data = [0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x12, 0x34, 0x56, 0x78, 0x9A].pack("C*")

    header = raw_header(0,
      asciiz("large_file.bin", 100),
      asciiz("", 155),
      binary_data,
      z(to_oct(0o12345, 7)))
    header = update_checksum(header)
    io = StringIO.new(header)
    h = Minitar::PosixHeader.from_stream(io)

    expected_size = 0x123456789A
    assert_equal expected_size, h.size
  end

  def test_parse_numeric_field_binary_negative_number
    binary_data = [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF].pack("C*")

    header = raw_header(0,
      asciiz("negative_size.bin", 100),
      asciiz("", 155),
      binary_data,
      z(to_oct(0o12345, 7)))

    header = update_checksum(header)
    io = StringIO.new(header)
    h = Minitar::PosixHeader.from_stream(io)

    expected_size = -1
    assert_equal expected_size, h.size
  end

  def test_parse_numeric_field_invalid
    ph = Minitar::PosixHeader
    assert_raises(ArgumentError) do
      ph.send(:parse_numeric_field, "invalid")
    end
    assert_raises(ArgumentError) do
      ph.send(:parse_numeric_field, "\x01\x02\x03")  # Invalid binary format
    end
  end
end
