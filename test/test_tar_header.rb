# frozen_string_literal: true

require "minitest_helper"

class TestTarHeader < Minitest::Test
  def test_arguments_are_checked
    assert_raises(ArgumentError) { new(name: "", size: "", mode: "") }
    assert_raises(ArgumentError) { new(name: "", size: "", prefix: "") }
    assert_raises(ArgumentError) { new(name: "", prefix: "", mode: "") }
    assert_raises(ArgumentError) { new(prefix: "", size: "", mode: "") }
  end

  def test_basic_headers
    assert_headers_equal build_tar_file_header("bla", "", 0o12345, 10),
      new(
        name: "bla",
        mode: 0o12345,
        size: 10,
        prefix: "",
        typeflag: "0"
      )

    assert_headers_equal build_tar_dir_header("bla", "", 0o12345),
      new(
        name: "bla",
        mode: 0o12345,
        size: 0,
        prefix: "",
        typeflag: "5"
      )
  end

  def test_long_name_works
    assert_headers_equal build_tar_file_header("a" * 100, "", 0o12345, 10),
      new(name: "a" * 100, mode: 0o12345, size: 10, prefix: "")

    assert_headers_equal build_tar_file_header("a" * 100, "bb" * 60, 0o12345, 10),
      new(name: "a" * 100, mode: 0o12345, size: 10, prefix: "bb" * 60)
  end

  def test_from_stream
    header = from_stream(
      build_tar_file_header("a" * 100, "", 0o12345, 10)
    )

    assert_equal "a" * 100, header.name
    assert_equal 0o12345, header.mode
    assert_equal 10, header.size
    assert_equal "", header.prefix
    assert_equal "ustar", header.magic
  end

  def test_from_stream_with_evil_name
    assert_equal "a ", from_stream(
      build_tar_file_header("a \0" + "\0" * 97, "", 0o12345, 10)
    ).name
  end

  def test_valid_with_valid_header
    assert from_stream(
      build_tar_file_header("a" * 100, "", 0o12345, 10)
    ).valid?
  end

  def test_from_stream_with_no_strict_octal
    assert_raises(ArgumentError) do
      from_stream(
        build_tar_file_header("a" * 100, "", 0o12345, -1213)
      )
    end
  end

  def test_from_stream_with_octal_wrapped_by_spaces
    assert_equal 651, from_stream(
      update_header_checksum(
        build_raw_header(
          0,
          asciiz("a" * 100, 100),
          asciiz("", 155),
          "       1213\0",
          z(octal(0o12345, 7))
        )
      )
    ).size
  end

  def test_valid_with_invalid_header
    refute from_stream("invalid").valid?
  end

  def test_setting_long_name_assigns_complete_path
    header = new(
      name: "short.txt",
      mode: 0o644,
      size: 100,
      prefix: "some/directory/path"
    )

    complete_path = "some/directory/path/very_long_filename_that_exceeds_one_hundred_characters_and_needs_gnu_extension.txt"
    header.long_name = complete_path

    assert_equal complete_path, header.name
  end

  def test_setting_long_name_clears_prefix_field
    header = new(
      name: "short.txt",
      mode: 0o644,
      size: 100,
      prefix: "some/directory/path"
    )

    complete_path = "some/directory/path/very_long_filename_that_exceeds_one_hundred_characters_and_needs_gnu_extension.txt"
    header.long_name = complete_path

    assert_equal "", header.prefix
  end

  def test_setting_long_name_with_nested_directories
    header = new(
      name: "file.txt",
      mode: 0o644,
      size: 50,
      prefix: "old/prefix"
    )

    complete_path = "deep/nested/directory/structure/with/very_long_filename_that_needs_gnu_long_name_extension_support.txt"
    header.long_name = complete_path

    assert_equal complete_path, header.name
    assert_equal "", header.prefix
  end

  def test_setting_long_name_with_empty_prefix
    header = new(
      name: "file.txt",
      mode: 0o644,
      size: 50,
      prefix: ""
    )

    complete_path = "very_long_filename_that_exceeds_one_hundred_characters_and_definitely_needs_gnu_extension_support.txt"
    header.long_name = complete_path

    assert_equal complete_path, header.name
    assert_equal "", header.prefix
  end

  def test_gnu_long_names_extension_is_detected
    assert new(
      name: Minitar::PosixHeader::GNU_EXT_LONG_LINK,
      mode: 0o644,
      size: 150,
      prefix: "",
      typeflag: "L"
    ).long_name?
  end

  def test_setting_long_name_with_very_long_path
    header = new(
      name: "file.txt",
      mode: 0o644,
      size: 100,
      prefix: "old/prefix"
    )

    long_dir = "very_long_directory_name_that_exceeds_normal_limits" * 5
    complete_path = "#{long_dir}/extremely_long_filename_with_many_characters.txt"
    header.long_name = complete_path

    assert_equal complete_path, header.name
    assert_equal "", header.prefix
  end

  def test_setting_long_name_with_single_filename_no_directories
    header = new(
      name: "short.txt",
      mode: 0o644,
      size: 100,
      prefix: "some/existing/prefix"
    )

    complete_path = "extremely_long_single_filename_without_any_directory_structure_that_exceeds_one_hundred_characters.txt"
    header.long_name = complete_path

    assert_equal complete_path, header.name
    assert_equal "", header.prefix
  end

  def test_setting_long_name_preserves_other_header_fields
    header = new(
      name: "short.txt",
      mode: 0o755,
      size: 12345,
      prefix: "old/prefix",
      uid: 1000,
      gid: 1000,
      mtime: 1234567890,
      typeflag: "0",
      linkname: "some_link"
    )

    complete_path = "new/very_long_path/that_exceeds_one_hundred_characters_and_needs_gnu_extension_support.txt"
    header.long_name = complete_path

    assert_equal complete_path, header.name
    assert_equal "", header.prefix

    assert_equal 0o755, header.mode
    assert_equal 12345, header.size
    assert_equal 1000, header.uid
    assert_equal 1000, header.gid
    assert_equal 1234567890, header.mtime
    assert_equal "0", header.typeflag
    assert_equal "some_link", header.linkname
  end

  def test_setting_name_with_empty_string
    header = new(
      name: "short.txt",
      mode: 0o644,
      size: 100,
      prefix: "some/prefix"
    )

    assert_raises(ArgumentError) do
      header.name = ""
    end
  end

  def test_setting_long_name_with_empty_string
    header = new(
      name: "short.txt",
      mode: 0o644,
      size: 100,
      prefix: "some/prefix"
    )

    assert_raises(ArgumentError) do
      header.long_name = ""
    end
  end

  def test_new_with_empty_string
    assert_raises(ArgumentError) do
      new(
        name: "",
        mode: 0o644,
        size: 100,
        prefix: "some/prefix"
      )
    end
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

    header = build_raw_header(
      0,
      asciiz("large_file.bin", 100),
      asciiz("", 155),
      binary_data,
      z(octal(0o12345, 7))
    )
    header = update_header_checksum(header)
    io = StringIO.new(header)
    h = Minitar::PosixHeader.from_stream(io)

    expected_size = 0x123456789A
    assert_equal expected_size, h.size
  end

  def test_parse_numeric_field_binary_negative_number
    binary_data = [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF].pack("C*")

    header = build_raw_header(
      0,
      asciiz("negative_size.bin", 100),
      asciiz("", 155),
      binary_data,
      z(octal(0o12345, 7))
    )

    header = update_header_checksum(header)
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

  private

  def from_stream(stream) =
    stream
      .then { _1.is_a?(String) ? StringIO.new(_1) : _1 }
      .then { Minitar::PosixHeader.from_stream(_1) }

  def new(header_hash) =
    Minitar::PosixHeader.new(header_hash)
end
