# -*- encoding: utf-8 -*-
# stub: archive-tar-minitar 0.6 ruby lib

Gem::Specification.new do |s|
  s.name = "archive-tar-minitar"
  s.version = "0.6"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Austin Ziegler"]
  s.date = "2017-02-06"
  s.description = "'archive-tar-minitar' has been deprecated; just install 'minitar'. The minitar library is a pure-Ruby library that provides the ability to deal\nwith POSIX tar(1) archive files.\n\nThis is release 0.6, \u{2026}\n\nminitar (previously called Archive::Tar::Minitar) is based heavily on code\noriginally written by Mauricio Julio Fern\u{e1}ndez Pradier for the rpa-base\nproject."
  s.email = ["halostatue@gmail.com"]
  s.files = ["lib/archive-tar-minitar.rb"]
  s.homepage = "https://github.com/halostatue/minitar/"
  s.licenses = ["Ruby", "BSD-2-Clause"]
  s.post_install_message = "'archive-tar-minitar' has been deprecated; just install 'minitar'."
  s.required_ruby_version = Gem::Requirement.new(">= 1.8")
  s.rubygems_version = "2.5.1"
  s.summary = "'archive-tar-minitar' has been deprecated; just install 'minitar'."

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<minitar>, ["~> 0.6"])
      s.add_runtime_dependency(%q<minitar-cli>, ["<= 1.0"])
    else
      s.add_dependency(%q<minitar>, ["~> 0.6"])
      s.add_dependency(%q<minitar-cli>, ["<= 1.0"])
    end
  else
    s.add_dependency(%q<minitar>, ["~> 0.6"])
    s.add_dependency(%q<minitar-cli>, ["<= 1.0"])
  end
end
