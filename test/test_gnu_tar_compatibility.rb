# frozen_string_literal: true

require "minitest_helper"

class TestGnuTarCompatibility < Minitest::Test
  def setup
    skip "GNU tar not available" unless has_gnu_tar?
  end

  def test_roundtrip_gnu_tar_cf_minitar_unpack
    # Use mixed filename scenarios from shared test utilities for comprehensive testing
    files = MIXED_FILENAME_SCENARIOS.dup
    # Add one very long filename to test GNU extension compatibility
    files[VERY_LONG_FILENAME_SCENARIOS.keys.first] = VERY_LONG_FILENAME_SCENARIOS.values.first

    workspace with_files: files do
      gnu_tar_create_in_workspace
      minitar_unpack_in_workspace

      assert_files_extracted_in_workspace
      refute_file_path_duplication_in_workspace
    end
  end

  def test_roundtrip_minitar_pack_gnu_tar_xf
    # Use different mixed scenarios for the reverse roundtrip test
    files = MIXED_FILENAME_SCENARIOS.dup
    # Add a different very long filename to test GNU extension compatibility
    files[VERY_LONG_FILENAME_SCENARIOS.keys.last] = VERY_LONG_FILENAME_SCENARIOS.values.last

    workspace with_files: files do
      gnu_tar_create_in_workspace
      minitar_unpack_in_workspace

      assert_files_extracted_in_workspace
    end
  end

  def test_roundtrip_gnu_tar_cf_minitar_unpack_mixed_filenames
    # Test GNU tar create → Minitar extract with mixed filename lengths
    files = {
      "short.txt" => "short content",
      "medium_length_filename.js" => "medium content",
      "#{"f" * 120}.css" => "long content",
      "dir/#{"g" * 130}.html" => "nested long content"
    }

    workspace with_files: files do
      gnu_tar_create_in_workspace
      minitar_unpack_in_workspace

      assert_files_extracted_in_workspace
      refute_file_path_duplication_in_workspace
    end
  end

  def test_minitar_writer_gnu_tar_xf_with_long_filenames
    # Test Minitar create → GNU tar extract with long filenames
    files = {
      "#{"j" * 120}.txt" => "content for 120 char filename",
      "nested/path/#{"k" * 110}.js" => "content for nested long filename",
      "#{"m" * 200}.html" => "content for very long filename",
      "regular_file.md" => "regular file content"
    }

    workspace with_files: files do
      minitar_writer_create_in_workspace
      gnu_tar_extract_in_workspace
      assert_files_extracted_in_workspace
    end
  end

  def test_gnu_tar_list_compatibility_with_long_filenames
    # Test that GNU tar can list files created by Minitar with long filenames
    files = {
      "#{"f" * 180}.data" => "gnu extension test content"
    }

    workspace with_files: files do
      minitar_writer_create_in_workspace

      list_output = gnu_tar_list_in_workspace
      files.each_key do |name|
        assert list_output.find { _1 == name },
          "#{name} not present in GNU tar list output: #{list_output}"
      end

      gnu_tar_extract_in_workspace
      assert_files_extracted_in_workspace
    end
  end
end
