# frozen_string_literal: true

require "base64"
require "fileutils"
require "minitar"
require "pathname"
require "stringio"
require "zlib"

gem "minitest"
require "minitest/autorun"
require "minitest/focus"

if ENV["STRICT"] != "false"
  $VERBOSE = true
  Warning[:deprecated] = true
  require "minitest/error_on_warning"
end

Dir.glob(File.join(__dir__, "support/**/*.rb")).sort.each do |support|
  require support
end
