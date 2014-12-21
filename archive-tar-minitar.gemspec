# -*- encoding: utf-8 -*-
# stub: archive-tar-minitar 0.6 ruby lib

Gem::Specification.new do |s|
  s.name = "archive-tar-minitar"
  s.version = "0.6"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Austin Ziegler"]
  s.date = "2014-12-21"
  s.description = "The minitar library is a pure-Ruby library and command-line utility that\nprovides the ability to deal with POSIX tar(1) archive files.\n\nThis is release 0.6, \u{2026}\n\nminitar (previously called Archive::Tar::Minitar) is based heavily on code\noriginally written by Mauricio Julio Fern\u{e1}ndez Pradier for the rpa-base\nproject."
  s.email = ["halostatue@gmail.com"]
  s.executables = ["minitar"]
  s.extra_rdoc_files = ["Contributing.rdoc", "History.rdoc", "Licence.rdoc", "Manifest.txt", "README.rdoc", "docs/COPYING.txt", "docs/ruby.txt", "Contributing.rdoc", "History.rdoc", "Licence.rdoc", "README.rdoc"]
  s.files = [".autotest", ".gemtest", ".gitignore", ".hoerc", "Contributing.rdoc", "History.rdoc", "Install", "Licence.rdoc", "Manifest.txt", "README.rdoc", "Rakefile", "bin/minitar", "docs/COPYING.txt", "docs/ruby.txt", "lib/archive-tar-minitar.rb", "lib/archive/tar/minitar.rb", "lib/archive/tar/minitar/command.rb", "lib/archive/tar/minitar/input.rb", "lib/archive/tar/minitar/output.rb", "lib/archive/tar/minitar/posix_header.rb", "lib/archive/tar/minitar/reader.rb", "lib/archive/tar/minitar/writer.rb", "lib/minitar.rb", "test/minitest_helper.rb", "test/test_tar_header.rb", "test/test_tar_input.rb", "test/test_tar_output.rb", "test/test_tar_reader.rb", "test/test_tar_writer.rb"]
  s.homepage = "https://github.com/halostatue/minitar/"
  s.licenses = ["Ruby", "GPL-2"]
  s.rdoc_options = ["--main", "README.rdoc"]
  s.required_ruby_version = Gem::Requirement.new(">= 1.8")
  s.rubygems_version = "2.4.2"
  s.summary = "The minitar library is a pure-Ruby library and command-line utility that provides the ability to deal with POSIX tar(1) archive files"
  s.test_files = ["test/test_tar_header.rb", "test/test_tar_input.rb", "test/test_tar_output.rb", "test/test_tar_reader.rb", "test/test_tar_writer.rb"]

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<minitest>, ["~> 5.4"])
      s.add_development_dependency(%q<rdoc>, ["~> 4.0"])
      s.add_development_dependency(%q<hoe-doofus>, ["~> 1.0"])
      s.add_development_dependency(%q<hoe-gemspec2>, ["~> 1.1"])
      s.add_development_dependency(%q<hoe-git>, ["~> 1.6"])
      s.add_development_dependency(%q<hoe-rubygems>, ["~> 1.0"])
      s.add_development_dependency(%q<hoe-travis>, ["~> 1.2"])
      s.add_development_dependency(%q<minitest-autotest>, ["< 2", ">= 1.0.b"])
      s.add_development_dependency(%q<rake>, ["~> 10.0"])
      s.add_development_dependency(%q<simplecov>, ["~> 0.7"])
      s.add_development_dependency(%q<coveralls>, ["~> 0.7"])
      s.add_development_dependency(%q<hoe>, ["~> 3.13"])
    else
      s.add_dependency(%q<minitest>, ["~> 5.4"])
      s.add_dependency(%q<rdoc>, ["~> 4.0"])
      s.add_dependency(%q<hoe-doofus>, ["~> 1.0"])
      s.add_dependency(%q<hoe-gemspec2>, ["~> 1.1"])
      s.add_dependency(%q<hoe-git>, ["~> 1.6"])
      s.add_dependency(%q<hoe-rubygems>, ["~> 1.0"])
      s.add_dependency(%q<hoe-travis>, ["~> 1.2"])
      s.add_dependency(%q<minitest-autotest>, ["< 2", ">= 1.0.b"])
      s.add_dependency(%q<rake>, ["~> 10.0"])
      s.add_dependency(%q<simplecov>, ["~> 0.7"])
      s.add_dependency(%q<coveralls>, ["~> 0.7"])
      s.add_dependency(%q<hoe>, ["~> 3.13"])
    end
  else
    s.add_dependency(%q<minitest>, ["~> 5.4"])
    s.add_dependency(%q<rdoc>, ["~> 4.0"])
    s.add_dependency(%q<hoe-doofus>, ["~> 1.0"])
    s.add_dependency(%q<hoe-gemspec2>, ["~> 1.1"])
    s.add_dependency(%q<hoe-git>, ["~> 1.6"])
    s.add_dependency(%q<hoe-rubygems>, ["~> 1.0"])
    s.add_dependency(%q<hoe-travis>, ["~> 1.2"])
    s.add_dependency(%q<minitest-autotest>, ["< 2", ">= 1.0.b"])
    s.add_dependency(%q<rake>, ["~> 10.0"])
    s.add_dependency(%q<simplecov>, ["~> 0.7"])
    s.add_dependency(%q<coveralls>, ["~> 0.7"])
    s.add_dependency(%q<hoe>, ["~> 3.13"])
  end
end
