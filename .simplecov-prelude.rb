require 'psych' if ENV['CI']
require 'simplecov'

if ENV['CI']
  require 'coveralls'
  SimpleCov.formatter = Coveralls::SimpleCov::Formatter
end

SimpleCov.start do
  command_name 'Minitest'
end

gem 'minitest'
