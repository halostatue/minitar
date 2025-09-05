# frozen_string_literal: true

require "minitest_helper"

class TestFilenameBoundaryConditions < Minitest::Test
  SCENARIOS = [99, 100, 101, 102, 154, 155, 156].each_with_object({}) { |len, map|
    name = "a" * len
    content = "#{len} chars content"
    map[name] = content

    define_method :"test_single_file_#{len}_chars" do
      file_map = {name => content}
      files = roundtrip_tar_string(file_map)
      assert_tar_structure_preserved file_map, files
    end

    name = "dir/#{"a" * (len - 4)}"
    content = "dir/ #{len - 4} chars content: #{len} total chars"
    map[name] = content

    define_method :"test_nested_file_total_#{len}_chars" do
      file_map = {name => content}
      files = roundtrip_tar_string(file_map)
      assert_tar_structure_preserved file_map, files
    end
  }

  posix_scenarios = [155, 156].each_with_object({}) { |len, map|
    name = "a" * len
    content = "#{len} chars content"
    map[name] = content

    define_method :"test_posix_boundary_#{len}_chars" do
      file_map = {name => content}
      files = roundtrip_tar_string(file_map)
      assert_tar_structure_preserved file_map, files
    end
  }

  posix_total_scenarios = {155 => 100, 165 => 110}.each_with_object({}) { |(k, v), map|
    name = "prefix_#{"a" * (k - 7)}/name_#{"a" * (v - 5)}"
    content = "prefix #{k} name #{v} chars"
    map[name] = content

    define_method :"test_posix_total_boundary_#{k + v + 1}_chars" do
      file_map = {name => content}
      files = roundtrip_tar_string(file_map)
      assert_tar_structure_preserved file_map, files
    end
  }

  name = "very_long_component_name_with_many_characters"
    .then { _1 * 3 }
    .then { [_1] }
    .then { _1 * 8 }
    .then { _1.join("/") }
    .then { "#{_1}/final_file_with_long_name.txt" }
  content = "Content for very long path"

  define_method :test_long_near_system_limits do
    file_map = {name => content}
    files = roundtrip_tar_string(file_map)
    assert_tar_structure_preserved file_map, files
  end

  SCENARIOS[name] = content

  SCENARIOS.merge!(posix_scenarios, posix_total_scenarios)

  def test_full_scenario_in_archive
    files = roundtrip_tar_string(SCENARIOS)
    assert_tar_structure_preserved(SCENARIOS, files)
  end
end
