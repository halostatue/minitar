# -*- ruby -*-

# NOTE: This file is present to keep Travis CI happy. Edits to it will not
# be accepted.

source 'https://rubygems.org/'

if RUBY_VERSION < '1.9'
  gem 'mime-types', '~> 1.25'
elsif RUBY_VERSION >= '2.0'
  gem 'byebug'
  gem 'simplecov', '~> 0.7'
  gem 'coveralls', '~> 0.7'
  gem 'mime-types', '~> 3.0'
else
  gem 'mime-types', '~> 2.0'
end

gemspec name: 'minitar'

# vim: syntax=ruby
