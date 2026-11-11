# frozen_string_literal: true

require "minitest_helper"

# Tests the private name normalization and relative path checks. These run on every
# platform because the alternate separator is passed as a parameter.
class TestPathNormalization < Minitest::Test
  def input
    @input ||= Minitar::Input.allocate
  end

  def normalize(name, alt_separator)
    input.send(:normalize_entry_name, name, alt_separator)
  end

  def check(name)
    input.send(:check_relative_path!, name)
  end

  # --- check_relative_path! (all platforms) ---

  def test_check_rejects_parent_components
    [
      "..", "../x", "a/..", "a/../b", "a/../../x", "a/b/.."
    ].each do |name|
      assert_raises(Minitar::SecureRelativePathError, name) { check(name) }
    end
  end

  def test_check_accepts_dots_within_a_component
    [
      "dirname../x", "..dirname/x", "a/dirname..", "a/..b/c", "...", "a/.../b", "a..b/c",
      ".hidden/x", "a/./b"
    ].each do |name|
      check(name)
    end

    pass
  end

  # --- nil alt_separator (POSIX): nothing but squeeze ---

  def test_nil_separator_keeps_backslashes_literal
    [
      "..\\x", "a\\..\\..\\x", "a\\..\\b", "..\\/x", "C:\\x", "C:x", "C:/x",
      "\\\\host\\share\\x", "a\\b", "a.txt:stream", "...\\x", "dirname..\\x", "a. \\x"
    ].each do |name|
      assert_equal name, normalize(name, nil)
      check(name)
    end
  end

  def test_nil_separator_squeezes_slashes
    assert_equal "a/b/c", normalize("a//b///c", nil)
  end

  # --- "\\" alt_separator (Windows semantics) ---

  def test_backslash_separator_rejects_traversal
    [
      "..\\x", "a\\..\\..\\x", "a\\..\\b", "..\\/x", "../x", "a/..\\x", "a\\..",
      "\\..\\x", "\\dir\\..\\x", "dir\\..\\..\\x"
    ].each do |name|
      assert_raises(Minitar::SecureRelativePathError, name) {
        check(normalize(name, "\\"))
      }
    end
  end

  def test_backslash_separator_rejects_dot_only_components
    [
      "...\\x", "....\\x", "a\\...\\b", "a\\...", ".. \\x", ".. .\\x", "a\\.. "
    ].each do |name|
      assert_raises(Minitar::UnsafeFileNameError, name) { normalize(name, "\\") }
    end
  end

  def test_backslash_separator_leaves_dot_and_dotdot_components_to_the_path_check
    assert_equal "a/./b", normalize("a\\.\\b", "\\")
    assert_equal "a/../b", normalize("a\\..\\b", "\\")
  end

  def test_backslash_separator_preserves_interior_dots
    [
      "a..b..c.txt", "a..b\\c.txt", "..a\\c.txt"
    ].each do |name|
      assert_equal name.tr("\\", "/"), normalize(name, "\\")
    end
  end

  def test_backslash_separator_rejects_trailing_dots_and_spaces
    [
      "dirname..\\x", "dir.\\x", "dir \\x", "a\\file.", "a\\file ", "foo...\\x"
    ].each do |name|
      assert_raises(Minitar::UnsafeFileNameError, name) { normalize(name, "\\") }
    end
  end

  def test_backslash_separator_accepts_ordinary_dots
    assert_equal "a/./b", normalize("a\\.\\b", "\\")
    assert_equal "dir..name/.hidden/a.b.txt/", normalize("dir..name\\.hidden\\a.b.txt\\", "\\")
  end

  def test_backslash_separator_converts_and_squeezes
    assert_equal "a/b", normalize("a\\b", "\\")
    assert_equal "a/b/c/d", normalize("a\\\\b//c\\/d", "\\")
  end

  def test_backslash_separator_rejects_drive_names
    [
      "C:\\x", "C:x", "C:/x", "c:\\x", "C:", "a\\C:\\x"
    ].each do |name|
      assert_raises(Minitar::UnsafeFileNameError, name) { normalize(name, "\\") }
    end
  end

  def test_backslash_separator_turns_unc_names_into_relative_paths
    {
      "\\\\host\\share\\x" => "/host/share/x",
      "//host/share/x" => "/host/share/x",
      "\\/host/share" => "/host/share",
      "\\\\host" => "/host"
    }.each do |name, expected|
      assert_equal expected, normalize(name, "\\")
      check(expected)
    end
  end

  def test_backslash_separator_rejects_alternate_data_streams
    [
      "a.txt:stream", "dir/a.txt:stream:$DATA", "dir:x/a", "a\\b:s"
    ].each do |name|
      assert_raises(Minitar::UnsafeFileNameError, name) { normalize(name, "\\") }
    end
  end

  def test_unsafe_file_name_error_is_a_minitar_error
    assert_operator Minitar::UnsafeFileNameError, :<, Minitar::Error
  end

  # --- end-to-end on POSIX: guards against over-normalizing ---

  def test_posix_extraction_keeps_backslash_names_literal
    skip "POSIX only" if Minitar.windows_separator?

    names = ["..\\x", "a\\..\\..\\x", "a\\b", "dirname../x"]
    Dir.mktmpdir do |root|
      dest = File.join(root, "dest")
      Minitar.unpack(tar_with(names), dest)

      assert_equal names.map { _1.sub(%r{/.*}, "") }.uniq.sort, Dir.children(dest).sort
      assert_path_exists File.join(dest, "..\\x")
      assert_path_exists File.join(dest, "dirname..", "x")
      assert_equal ["dest"], Dir.children(root)
    end
  end

  private

  def tar_with(names)
    io = StringIO.new(+"".b)
    Minitar::Writer.open(io) do |w|
      names.each do |name|
        w.add_file_simple(name, mode: 0o644, size: 1) { _1.write("x") }
      end
    end
    io.rewind
    io
  end
end
