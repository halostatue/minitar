# frozen_string_literal: true

module Minitar::TestHelpers
  TIME_2004 = Time.utc(2004).to_i

  BOUNDARY_SCENARIOS = {
    ("a" * 99) => "99 chars content",
    ("a" * 100) => "100 chars content",
    ("a" * 101) => "101 chars content",
    ("a" * 102) => "102 chars content",
    "dir/#{"a" * 96}" => "nested path 100 total content",
    "dir/#{"a" * 97}" => "nested path 101 total content",
    "nested/#{"d" * 93}" => "nested 100 total content",
    "nested/#{"e" * 94}" => "nested 101 total content"
  }.freeze

  MIXED_FILENAME_SCENARIOS = {
    "short.txt" => "short content",
    "medium_length_filename_under_100_chars.txt" => "medium content",
    "dir1/medium_filename.js" => "medium nested content",
    "#{"x" * 120}.txt" => "long content",
    "nested/dir/#{"y" * 110}.css" => "long nested content"
  }.freeze

  VERY_LONG_FILENAME_SCENARIOS = {
    "#{"f" * 180}.data" => "180 char filename content",
    "#{"g" * 200}.json" => "200 char filename content",
    "nested/path/#{"h" * 150}.css" => "nested long filename content",
    "deep/nested/structure/#{"i" * 170}.html" => "deeply nested long content",
    "project/src/main/#{"j" * 160}.java" => "project structure long content"
  }.freeze

  private

  Minitest::Test.send(:include, self)
end
