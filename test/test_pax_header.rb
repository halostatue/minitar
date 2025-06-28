require "minitest_helper"

class TestPaxHeader < Minitest::Test
  def test_from_stream_with_size_attribute
    pax_content = "19 size=8614356715\n28 mtime=1749098832.3200000\n"
    pax_header = create_pax_header_from_stream(pax_content)

    assert_equal 8614356715, pax_header.size
    assert_equal "1749098832.3200000", pax_header.attributes["mtime"]
  end

  def test_from_stream_without_size_attribute
    pax_content = "28 mtime=1749098832.3200000\n27 path=some/long/path.txt\n"
    pax_header = create_pax_header_from_stream(pax_content)

    assert_nil pax_header.size
    assert_equal "some/long/path.txt", pax_header.path
    assert_equal 1749098832.32, pax_header.mtime
  end

  def test_parse_multiline_values
    pax_content = "22 foo=one\ntwo\nthree\n\n12 bar=four\n"
    pax_header = Minitar::PaxHeader.from_data(pax_content)
    assert_equal "one\ntwo\nthree\n", pax_header.attributes["foo"]
    assert_equal "four", pax_header.attributes["bar"]
  end

  def test_from_stream_with_invalid_header
    header_data = tar_file_header("regular_file.txt", "", 0o644, 100)
    io = StringIO.new(header_data)

    posix_header = Minitar::PosixHeader.from_stream(io)
    refute posix_header.pax_header?

    assert_raises(ArgumentError, "Header must be a PAX header") do
      Minitar::PaxHeader.from_stream(io, posix_header)
    end
  end

  def test_parse_content_with_multiple_attributes
    pax_content = "19 size=8614356715\n28 mtime=1749098832.3200000\n27 path=some/long/path.txt\n"

    pax_header = Minitar::PaxHeader.from_data(pax_content)

    assert_equal 8614356715, pax_header.size
    assert_equal "some/long/path.txt", pax_header.path
    assert_equal 1749098832.32, pax_header.mtime

    # Check raw attributes
    assert_equal "8614356715", pax_header.attributes["size"]
    assert_equal "1749098832.3200000", pax_header.attributes["mtime"]
    assert_equal "some/long/path.txt", pax_header.attributes["path"]
  end

  def test_parse_content_with_invalid_length_format
    assert_raises(ArgumentError) do
      Minitar::PaxHeader.from_data("19 size=8614356715\ninvalid line\n23 path=valid/path.txt\n")
    end
  end

  def test_parse_content_with_oversized_record
    assert_raises(ArgumentError) do
      Minitar::PaxHeader.from_data("19 size=8614356715\n999 toolong=value\n")
    end
  end

  def test_from_stream_strips_padding
    pax_content = "19 size=8614356715\n"
    pax_header = create_pax_header_from_stream(pax_content)

    # Should parse only the actual content, ignoring padding
    assert_equal 8614356715, pax_header.size
    assert_equal 1, pax_header.attributes.size  # Only one attribute parsed

    # Should have parsed content correctly
    assert_equal 1, pax_header.attributes.size
    assert_equal "8614356715", pax_header.attributes["size"]
  end

  def test_attributes_accessor
    pax_content = "19 size=8614356715\n23 custom=custom_value\n"
    pax_header = Minitar::PaxHeader.from_data(pax_content)

    assert_equal "8614356715", pax_header.attributes["size"]
    assert_equal "custom_value", pax_header.attributes["custom"]
    assert_nil pax_header.attributes["nonexistent"]
  end

  def test_pax_header_to_s
    pax_header = Minitar::PaxHeader.new(size: "8614356715", mtime: "1749098832.3200000")
    assert_equal "19 size=8614356715\n28 mtime=1749098832.3200000\n", pax_header.to_s
  end

  private

  def create_pax_header_from_stream(pax_content, name = "./PaxHeaders.X/test_file")
    pax_header_data = tar_pax_header(name, "", pax_content.bytesize)
    padded_content = pax_content.ljust(((pax_content.bytesize / 512.0).ceil * 512), "\0")
    io = StringIO.new(pax_header_data + padded_content)

    posix_header = Minitar::PosixHeader.from_stream(io)
    Minitar::PaxHeader.from_stream(io, posix_header)
  end
end
