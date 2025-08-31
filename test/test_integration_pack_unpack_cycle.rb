# frozen_string_literal: true

require "minitest_helper"

class TestIntegrationPackUnpackCycle < Minitest::Test
  def test_comprehensive
    files = MIXED_FILENAME_SCENARIOS.merge(
      VERY_LONG_FILENAME_SCENARIOS,
      BOUNDARY_SCENARIOS,
      {
        "empty_dir" => nil,
        "nested/empty" => nil,
        "long_dir_#{"i" * 120}" => nil,
        "root_file.txt" => "root content",
        "level1/file1.txt" => "level1 content",
        "level1/level2/file2.txt" => "level2 content",
        "level1/level2/level3/#{"deep" * 30}.txt" => "deep nested with long name",
        "#{"long_dir" * 20}/file_in_long_dir.txt" => "file in long directory name",
        "mixed/#{"long_subdir" * 15}/#{"long_file" * 25}.txt" => "long dir and file names"
      }
    )

    workspace with_files: files do |ws|
      minitar_pack_in_workspace

      assert ws.tarball.file?, "Tarball does not exist"
      assert ws.tarball.size > 0, "Tarball should not be empty"

      minitar_unpack_in_workspace

      assert_files_extracted_in_workspace
      refute_file_path_duplication_in_workspace

      assert_extracted_files_match_source_files_in_workspace
      assert_file_modes_match_in_workspace
    end
  end
end
