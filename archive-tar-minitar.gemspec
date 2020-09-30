# -*- encoding: utf-8 -*-
# stub: archive-tar-minitar 0.9 ruby lib

Gem::Specification.new do |s|
  s.name = "archive-tar-minitar".freeze
  s.version = "0.9"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/halostatue/minitar/issues", "homepage_uri" => "https://github.com/halostatue/minitar/", "source_code_uri" => "https://github.com/halostatue/minitar/" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Austin Ziegler".freeze]
  s.date = "2020-09-29"
  s.description = "'archive-tar-minitar' has been deprecated; just install 'minitar'. The minitar library is a pure-Ruby library that provides the ability to deal\nwith POSIX tar(1) archive files.\n\nThis is release 0.9, adding a minor feature to Minitar.unpack and\nMinitar::Input#extract_entry that when <tt>:fsync => false</tt> is provided,\nfsync will be skipped.\n\nminitar (previously called Archive::Tar::Minitar) is based heavily on code\noriginally written by Mauricio Julio Fern\u00E1ndez Pradier for the rpa-base\nproject.".freeze
  s.email = ["halostatue@gmail.com".freeze]
  s.files = ["lib/archive-tar-minitar.rb".freeze]
  s.homepage = "https://github.com/halostatue/minitar/".freeze
  s.licenses = ["Ruby".freeze, "BSD-2-Clause".freeze]
  s.post_install_message = "'archive-tar-minitar' has been deprecated; just install 'minitar'.".freeze
  s.required_ruby_version = Gem::Requirement.new(">= 1.8".freeze)
  s.rubygems_version = "3.2.0.rc.1".freeze
  s.summary = "'archive-tar-minitar' has been deprecated; just install 'minitar'.".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<minitar>.freeze, ["~> 0.9"])
    s.add_runtime_dependency(%q<minitar-cli>.freeze, ["~> 0.9"])
  else
    s.add_dependency(%q<minitar>.freeze, ["~> 0.9"])
    s.add_dependency(%q<minitar-cli>.freeze, ["~> 0.9"])
  end
end
