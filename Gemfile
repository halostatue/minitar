# -*- ruby -*-

# NOTE: This file is present to keep Travis CI happy. Edits to it will not
# be accepted.

source 'https://rubygems.org/'

mime_version =
  if RUBY_VERSION < '1.9'
    '1.25'
  elsif RUBY_VERSION < '2.0'
    '2.0'
  else
    '3.0'
  end

gem 'mime-types', "~> #{mime_version}"

platforms :mri_20, :mri_21, :mri_22, :mri_23 do
  gem 'byebug'
  gem 'simplecov', '~> 0.7'
  gem 'coveralls', '~> 0.7'
end

gemspec name: 'minitar'

# vim: syntax=ruby
