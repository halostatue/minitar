# frozen_string_literal: true

# Test assertions and helpers for working with tarballs.
#
# Includes Minitar in-memory and on-disk operations and GNU tar helpers.
module Minitar::TestHelpers::Tarball
  private

  tar_version = `tar --version`

  GNU_TAR =
    case tar_version
    when /\(GNU tar\)|Free Software Foundation/
      `which tar`.chomp
    when /bsdtar/
      `which gtar`.chomp
    end.freeze

  # Given the +original_files+ file hash (input to +create_tar_string+) and the
  # +extracted_files+ file has (output from +extract_tar_string+), ensures that the tar
  # structure is preserved, including checking for possible regression of issue 52.
  #
  # Such a regression would result in a directory like <tt>>/b/c.txt</tt> looking like
  # <tt>a/b/a/b/c.txt</tt> (but only for long filenames).
  def assert_tar_structure_preserved(original_files, extracted_files)
    assert_equal original_files.length, extracted_files.length

    extracted_paths = extracted_files.keys.sort

    original_files.each do |filename, content|
      assert extracted_files.key?(filename), "File #{filename} should be extracted"

      assert_equal content, extracted_files[filename], "Content should be preserved for #{filename}"

      next unless filename.include?("/")

      dirname, basename = File.split(filename)
      bad_pattern = File.join(dirname, dirname, basename)

      duplicated_paths = extracted_paths.select { |path| path == bad_pattern }

      refute duplicated_paths.any?,
        "Regression of #52, path duplication on extraction! " \
        "Original: #{filename}, " \
        "Bad pattern found: #{bad_pattern}, " \
        "All extracted paths: #{extracted_paths}"
    end
  end

  # Create a tarball string from the +file_hash+ (<tt>{filename => content}</tt>).
  def create_tar_string(file_hash) =
    StringIO.new.tap { |io|
      Minitar::Output.open(io) do |output|
        file_hash.each do |filename, content|
          Minitar.pack_as_file(filename, content.to_s.dup, output)
        end
      end
    }.string

  # Extract a hash of <tt>{filename => content}</tt> from the +tar_data+. Directories are
  # skipped.
  def extract_tar_string(tar_data) =
    {}.tap { |files|
      Minitar::Input.open(StringIO.new(tar_data)) do |input|
        input.each do |entry|
          next if entry.directory?
          files[entry.full_name] = entry.read
        end
      end
    }

  # Create a tarball string from the +file_hash+ (<tt>{filename => content}</tt>) provided
  # and immediately extracts a hash of <tt>{filename => content}</tt> from the tarball
  # string. Directories are skipped.
  def roundtrip_tar_string(file_hash) =
    create_tar_string(file_hash).then { extract_tar_string(_1) }

  def has_gnu_tar? = !GNU_TAR&.empty?

  Workspace = Struct.new(:tmpdir, :source, :target, :tarball, :files, keyword_init: true)

  # Prepare a workspace for a file-based test.
  def workspace(with_files: nil)
    raise "No nested workspace permitted" if @workspace

    tmpdir =
      if Pathname.respond_to?(:mktmpdir)
        Pathname.mktmpdir
      else
        Pathname(Dir.mktmpdir)
      end
    source = tmpdir.join("source").mkpath
    target = tmpdir.join("target").mkpath
    tarball = tmpdir.join("test.tar")

    @workspace = Workspace.new(source:, tarball:, target:, tmpdir:)

    prepare_workspace(with_files:) if with_files

    yield @workspace
  ensure
    tmpdir&.rmtree
    @workspace = nil
  end

  def prepare_workspace(with_files:)
    missing_workspace!
    raise "Missing workspace" unless @workspace
    raise "Files already prepared" if @workspace.files

    @workspace.files = with_files.each_pair do
      full_path = @workspace.source.join(_1)

      if _2.nil?
        full_path.mkpath
      else
        full_path.dirname.mkpath
        full_path.write(_2)
      end
    end
  end

  def gnu_tar_create_in_workspace
    missing_workspace!
    system(GNU_TAR, "-cf", @workspace.tarball.to_s, "-C", @workspace.source.to_s, ".")
  end

  def gnu_tar_extract_in_workspace
    missing_workspace!
    system(GNU_TAR, "-xf", @workspace.tarball.to_s, "-C", @workspace.target.to_s)
  end

  def gnu_tar_list_in_workspace
    missing_workspace!
    `#{GNU_TAR} -tf "#{@workspace.tarball}" 2>/dev/null`.strip.split($/)
  end

  def minitar_pack_in_workspace
    missing_workspace!
    @workspace.tarball.open("wb") do |tar_io|
      Dir.chdir(@workspace.source) do
        Minitar.pack(".", tar_io)
      end
    end
  end

  def minitar_unpack_in_workspace
    missing_workspace!
    @workspace.tarball.open("rb") do
      Minitar.unpack(_1, @workspace.target)
    end
  end

  def minitar_writer_create_in_workspace
    missing_workspace!
    @workspace.tarball.open("wb") do |tar_io|
      Minitar::Writer.open(tar_io) do |writer|
        @workspace.files.each_pair do |name, content|
          full_path = @workspace.source.join(name)
          stat = full_path.stat

          writer.add_file_simple(name, mode: stat.mode, size: stat.size) do
            _1.write(content)
          end
        end
      end
    end
  end

  def assert_files_extracted_in_workspace
    missing_workspace!
    @workspace.files.each_pair do
      target = @workspace.target.join(_1)
      assert target.exist?, "#{_1.inspect} does not exist"

      if _2.nil?
        assert target.directory?, "#{_1} is not a directory"
      else
        assert_equal _2, @workspace.target.join(_1).read, "#{_1} content does not match"
      end
    end
  end

  def refute_file_path_duplication_in_workspace
    missing_workspace!
    @workspace.files.each_key do
      next unless _1.include?("/")

      dir, filename = Pathname(_1).split
      dup_path = dir.join(dir, filename)
      refute @workspace.target.join(dup_path).exist?,
        "No path duplication should occur: #{dup_path}"
    end
  end

  def assert_extracted_files_match_source_files_in_workspace
    missing_workspace!

    source_files = __collect_relative_paths(@workspace.source)
    target_files = __collect_relative_paths(@workspace.target)

    assert_equal source_files, target_files,
      "Complete directory structure should match exactly"
  end

  def __collect_relative_paths(dir)
    return [] unless dir.directory?

    dir.glob("**/*").map { _1.relative_path_from(dir).to_s }.sort
  end

  def assert_file_modes_match_in_workspace
    return if Minitar.windows?

    missing_workspace!

    @workspace.files.each_key do |file_path|
      source = @workspace.source.join(file_path)
      target = @workspace.target.join(file_path)

      source_mode = source.stat.mode & 0o777
      target_mode = target.stat.mode & 0o777

      assert_modes_equal source_mode, target_mode, file_path
    end
  end

  def missing_workspace!
    raise "Missing workspace" unless defined?(@workspace)
  end

  Minitest::Test.send(:include, self)
end
