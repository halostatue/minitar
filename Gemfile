# -*- ruby -*-

# NOTE: This file is present to keep Travis CI happy. Edits to it will not
# be accepted, except to remove all of this crap later.

source 'https://rubygems.org/'

mime_version =
  if RUBY_VERSION < '1.9'
    gem 'rdoc', '< 4.0'
    # gem 'ruby-debug'
    '1.25'
  elsif RUBY_VERSION < '2.0'
    # gem 'debugger' if RUBY_ENGINE == 'ruby'
    '2.0'
  elsif RUBY_VERSION >= '2.0'
    if RUBY_ENGINE == 'ruby'
      # gem 'byebug'
      gem 'simplecov', '~> 0.7'
      gem 'coveralls', '~> 0.7'
    end
    '3.0'
  end

gem 'mime-types', "~> #{mime_version}"

gemspec :name => 'minitar'

# vim: syntax=ruby
