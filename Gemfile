# frozen_string_literal: true

# NOTE: This file is not the canonical source of dependencies. Edit the
# Rakefile, instead.

source "https://rubygems.org/"

mime_version =
  if RUBY_VERSION < "1.9"
    gem "rdoc", "< 4.0"
    gem "rake", "~> 10.0"
    "1.25"
  elsif RUBY_VERSION < "2.0"
    gem "rdoc", "< 6.0"
    "2.0"
  elsif RUBY_VERSION >= "2.0"
    "3.0"
  end

gem "mime-types", "~> #{mime_version}"

gemspec :name => "minitar"
