require "minitest_helper"

class TestPaxSupport < Minitest::Test
  def test_pax_header_size_extraction_in_reader
    pax_content = "16 size=1048576\n28 mtime=1749098832.3200000\n"
    tar_data = create_pax_with_file_headers(pax_content, "./PaxHeaders.X/large_file.mov", "large_file.mov", 1048576, 0)

    entries = read_tar_entries(tar_data)
    assert_equal 1, entries.size

    entry = entries.first
    assert_equal "large_file.mov", entry.name
    assert_equal 1048576, entry.size  # Size from PAX header
  end

  def test_pax_header_without_size_uses_header_size
    pax_content = "28 mtime=1749098832.3200000\n"
    tar_data = create_pax_with_file_headers(pax_content, "./PaxHeaders.X/normal_file.txt", "normal_file.txt", 12345, 12345)

    entries = read_tar_entries(tar_data)
    assert_equal 1, entries.size

    entry = entries.first
    assert_equal "normal_file.txt", entry.name
    assert_equal 12345, entry.size  # Original header size preserved
  end

  def test_pax_header_takes_precedence_over_posix_header_size
    pax_content = "16 size=1048576\n28 mtime=1749098832.3200000\n"
    tar_data = create_pax_with_file_headers(pax_content, "./PaxHeaders.X/precedence_file.txt", "precedence_file.txt", 12345, 12345)

    entries = read_tar_entries(tar_data)
    assert_equal 1, entries.size

    entry = entries.first
    assert_equal "precedence_file.txt", entry.name
    assert_equal 1048576, entry.size  # PAX size takes precedence over POSIX size (12345)
  end

  def test_pax_size_extraction_logic
    pax_header_with_size = Minitar::PaxHeader.new(size: "1048576", mtime: "1749098832.3200000")
    assert_equal 1048576, pax_header_with_size.size

    pax_header_without_size = Minitar::PaxHeader.new(mtime: "1749098832.3200000")
    assert_nil pax_header_without_size.size
  end

  private

  def read_tar_entries(tar_data)
    io = StringIO.new(tar_data)
    Minitar::Reader.open(io, &:to_a)
  end

  def create_pax_with_file_headers(pax_content, pax_name, file_name, file_size, posix_header_file_size)
    file_content = "x" * file_size
    padded_file_content = file_content.ljust((file_size / 512.0).ceil * 512, "\0")

    [
      build_tar_pax_header(pax_name, "", pax_content.bytesize),
      pax_content.ljust((pax_content.bytesize / 512.0).ceil * 512, "\0"),
      build_tar_file_header(file_name, "", 0o644, file_size),
      padded_file_content
    ].join
  end
end
