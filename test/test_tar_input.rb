# frozen_string_literal: true

require "minitest_helper"

class TestTarInput < Minitest::Test
  TEST_CONTENTS = {
    "data.tar.gz" => {size: 210, mode: 0o644},
    "file3" => {size: 18, mode: 0o755}
  }.freeze

  TEST_DATA_CONTENTS = {
    "data/" => {size: 0, mode: 0o755},
    "data/__dir__/" => {size: 0, mode: 0o755},
    "data/file1" => {size: 16, mode: 0o644},
    "data/file2" => {size: 16, mode: 0o644}
  }.freeze

  def setup
    @reader = open_fixture("tar_input")
    FileUtils.mkdir_p("data__")
  end

  def teardown
    @reader&.close unless @reader&.closed?
    FileUtils.rm_rf("data__")
  end

  def test_open_no_block
    input = Minitar::Input.open(@reader)
    refute input.closed?
  ensure
    input.close
    assert input.closed?
  end

  def test_each_works
    Minitar::Input.open(@reader) do |stream|
      outer = 0
      stream.each.with_index do |entry, i|
        assert_kind_of Minitar::Reader::EntryStream, entry
        assert TEST_CONTENTS.key?(entry.name)

        assert_equal TEST_CONTENTS[entry.name][:size], entry.size, entry.name
        assert_modes_equal(TEST_CONTENTS[entry.name][:mode],
          entry.mode, entry.name)
        assert_equal TIME_2004, entry.mtime, "entry.mtime"

        if i.zero?
          data_reader = Zlib::GzipReader.new(StringIO.new(entry.read))
          Minitar::Input.open(data_reader) do |is2|
            inner = 0
            is2.each_with_index do |entry2, _j|
              assert_kind_of Minitar::Reader::EntryStream, entry2
              assert TEST_DATA_CONTENTS.key?(entry2.name)
              assert_equal(TEST_DATA_CONTENTS[entry2.name][:size], entry2.size,
                entry2.name)
              assert_modes_equal(TEST_DATA_CONTENTS[entry2.name][:mode],
                entry2.mode, entry2.name)
              assert_equal TIME_2004, entry2.mtime, entry2.name
              inner += 1
            end
            assert_equal 4, inner
          end
        end

        outer += 1
      end

      assert_equal 2, outer
    end
  end

  def test_extract_entry_works
    Minitar::Input.open(@reader) do |stream|
      outer_count = 0
      stream.each_with_index do |entry, i|
        stream.extract_entry("data__", entry)
        name = File.join("data__", entry.name)

        assert TEST_CONTENTS.key?(entry.name)

        if entry.directory?
          assert(File.directory?(name))
        else
          assert(File.file?(name))

          assert_equal TEST_CONTENTS[entry.name][:size], File.stat(name).size
        end

        assert_modes_equal(TEST_CONTENTS[entry.name][:mode],
          File.stat(name).mode, entry.name)

        if i.zero?
          begin
            ff = File.open(name, "rb")
            data_reader = Zlib::GzipReader.new(ff)
            Minitar::Input.open(data_reader) do |is2|
              is2.each_with_index do |entry2, _j|
                is2.extract_entry("data__", entry2)
                name2 = File.join("data__", entry2.name)

                assert TEST_DATA_CONTENTS.key?(entry2.name)

                if entry2.directory?
                  assert(File.directory?(name2))
                else
                  assert(File.file?(name2))
                  assert_equal(TEST_DATA_CONTENTS[entry2.name][:size],
                    File.stat(name2).size)
                end
                assert_modes_equal(TEST_DATA_CONTENTS[entry2.name][:mode],
                  File.stat(name2).mode, name2)
              end
            end
          ensure
            ff.close unless ff.closed?
          end
        end

        outer_count += 1
      end

      assert_equal 2, outer_count
    end
  end

  def test_extract_entry_breaks_symlinks
    return if Minitar.windows?

    IO.respond_to?(:write) &&
      IO.write("data__/file4", "") ||
      File.write("data__/file4", "")

    File.symlink("data__/file4", "data__/file3")
    File.symlink("data__/file4", "data__/data")

    Minitar.unpack(@reader, "data__")
    Minitar.unpack(Zlib::GzipReader.new(File.open("data__/data.tar.gz", "rb")),
      "data__")

    refute File.symlink?("data__/file3")
    refute File.symlink?("data__/data")
  end

  def test_extract_entry_fails_with_relative_directory
    reader = open_fixture("test_input_relative")
    Minitar::Input.open(reader) do |stream|
      stream.each do |entry|
        assert_raises Minitar::SecureRelativePathError do
          stream.extract_entry("data__", entry)
        end
      end
    end
  end

  def test_extract_with_non_strict_octal
    reader = open_fixture("test_input_non_strict_octal")

    assert_raises(ArgumentError) do
      Minitar.unpack(reader, "data__")
    end
  end

  def test_extract_octal_wrapped_by_space
    reader = open_fixture("test_input_space_octal")
    header = Minitar::PosixHeader.from_stream(reader)
    assert_equal 210, header.size

    reader = open_fixture("test_input_space_octal")
    Minitar.unpack(reader, "data__", [])
  end

  def test_fsync_false
    outer = 0
    Minitar.unpack(@reader, "data__", [], fsync: false) do |_label, _path, _stats|
      outer += 1
    end
    assert_equal 6, outer
  end
end
