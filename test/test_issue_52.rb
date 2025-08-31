# frozen_string_literal: true

require "minitest_helper"

class TestIssue52 < Minitest::Test
  # These are representative filenames from issue #52 which were extracted incorrectly.
  FILENAMES = [
    "hpg5lfg/1j/973e4t/hqc/djcrcb1l49ardcthyl5u80dcgmo03cp5mh938wr38dka7us1ja4i3dfrp3ahg4q2ooet6avyw45nqpzrcxfzdemvzj07oftcghtkl5bdc.gz",
    "hpg5lfg/1j/973e4t/hqc/mioxx4h9tgcc9gqw0j8z2fj2covf6nsplrwggyjsg4swmh0glzy2jji4n2gspvb2vlki7zmu81046hvgt4fstlk6fldv0p1w3nf7o6.css",
    "k6hly56/mh/ri2pa1/04/0afdks3r6k1mbf64xzuwh5efkuxurro63rbckjssmz9mdratf6ayfduqpb0r9qxx2mgnrs0thi0ohh4qtfylfd6cd506zawwic0u3ec0iluu4myn.map",
    "k6hly56/mh/ri2pa1/04/5k8mnvwxe7hmvp1n932o4mn2b25gqrxfrbe4jfjbig6kzhphnsfkrtqruypfzl93u0ohlv9yyxcoxn6jg6iv5ml8e27jdqjiikyq3.js"
  ].freeze

  FILENAMES.each do |filename|
    first, *, last = filename.split("/")
    last = File.extname(last)

    define_method :"test_issue_52_path_#{first}_#{last}" do
      file_map = {filename => "Test content for #{File.basename(filename)}"}
      files = roundtrip_tar_string(file_map)

      assert_tar_structure_preserved file_map, files
    end
  end

  def test_issue_52_full_regression
    file_map = FILENAMES.each_with_object({}) { |name, map|
      map[name] = "Test content for #{File.basename(name)}"
    }
    files = roundtrip_tar_string(file_map)

    assert_tar_structure_preserved file_map, files
  end

  def test_issue_52_mixed_filename_lengths_no_regression
    file_map = MIXED_FILENAME_SCENARIOS.dup
    FILENAMES.each { file_map[_1] = "content for problematic filename #{_1}" }

    files = roundtrip_tar_string(file_map)

    assert_tar_structure_preserved file_map, files
  end

  def test_issue_52_very_long_filenames_no_regression
    file_map = VERY_LONG_FILENAME_SCENARIOS.dup
    files = roundtrip_tar_string(file_map)

    assert_tar_structure_preserved file_map, files
  end
end
