# frozen_string_literal: true

require "minitest_helper"

# End-to-end extraction tests that depend on real Windows path semantics. These are
# skipped everywhere else.
class TestWindowsExtraction < Minitest::Test
  def setup
    skip "Windows only" unless Minitar.windows_separator?
  end

  TRAVERSAL_NAMES = [
    "..\\escaped.txt", "a\\..\\..\\escaped.txt", "..\\/escaped.txt", "../escaped.txt"
  ].freeze

  def test_traversal_names_are_rejected_and_nothing_escapes
    TRAVERSAL_NAMES.each do |name|
      with_dest do |root, dest|
        assert_raises(Minitar::SecureRelativePathError, name) {
          Minitar.unpack(tar_with(name), dest)
        }
        assert_equal [
          "dest"
        ], Dir.children(root), name
      end
    end
  end

  def test_drive_names_are_rejected
    [
      "C:\\escaped.txt", "C:escaped.txt", "C:/escaped.txt"
    ].each do |name|
      with_dest do |root, dest|
        assert_raises(Minitar::UnsafeFileNameError, name) {
          Minitar.unpack(tar_with(name), dest)
        }
        assert_equal ["dest"], Dir.children(root), name
        assert_empty Dir.children(dest)
      end
    end
  end

  def test_unc_names_extract_as_relative_paths_inside_destdir
    [
      "\\\\host\\share\\c.txt", "//host/share/c.txt"
    ].each do |name|
      with_dest do |root, dest|
        Minitar.unpack(tar_with(name), dest)

        assert_equal ["dest"], Dir.children(root), name
        assert_path_exists File.join(dest, "host", "share", "c.txt")
      end
    end
  end

  def test_alternate_data_streams_are_rejected
    with_dest do |root, dest|
      assert_raises(Minitar::UnsafeFileNameError) {
        Minitar.unpack(tar_with("a.txt:stream"), dest)
      }
      assert_empty Dir.children(dest)
    end
  end

  def test_backslash_name_extracts_as_nested_path
    with_dest do |_, dest|
      Minitar.unpack(tar_with("a\\b\\c.txt"), dest)

      assert_equal "x", File.read(File.join(dest, "a", "b", "c.txt"))
    end
  end

  def test_dots_within_a_component_are_accepted
    with_dest do |_, dest|
      Minitar.unpack(tar_with("dir..name\\c.txt"), dest)

      assert_path_exists File.join(dest, "dir..name", "c.txt")
    end
  end

  def test_dot_only_and_trailing_dot_components_are_rejected
    [
      "...\\escaped.txt", "a\\...\\escaped.txt", ".. \\escaped.txt"
    ].each do |name|
      with_dest do |root, dest|
        assert_raises(Minitar::UnsafeFileNameError, name) {
          Minitar.unpack(tar_with(name), dest)
        }
        assert_equal [
          "dest"
        ], Dir.children(root), name
      end
    end

    with_dest do |_, dest|
      assert_raises(Minitar::UnsafeFileNameError) {
        Minitar.unpack(tar_with("dirname..\\c.txt"), dest)
      }
      assert_empty Dir.children(dest)
    end
  end

  private

  def with_dest
    Dir.mktmpdir do |root|
      dest = File.join(root, "dest")
      Dir.mkdir(dest)
      yield root, dest
    end
  end

  def tar_with(name)
    io = StringIO.new(+"".b)
    Minitar::Writer.open(io) do |w|
      w.add_file_simple(name, mode: 0o644, size: 1) { _1.write("x") }
    end
    io.rewind
    io
  end
end
