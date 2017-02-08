# -*- encoding: utf-8 -*-
# stub: minitar 0.6.1 ruby lib

Gem::Specification.new do |s|
  s.name = "minitar"
  s.version = "0.6.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Austin Ziegler"]
  s.date = "2017-02-08"
  s.description = "The minitar library is a pure-Ruby library that provides the ability to deal\nwith POSIX tar(1) archive files.\n\nThis is release 0.6, providing a number of bug fixes including a directory\ntraversal vulnerability, CVE-2016-10173. This release starts the migration and\nmodernization of the code:\n\n*   the licence has been changed to match the modern Ruby licensing scheme\n    (Ruby and Simplified BSD instead of Ruby and GNU GPL);\n*   the +minitar+ command-line program has been separated into the\n    +minitar-cli+ gem; and\n*   the +archive-tar-minitar+ gem now points to the +minitar+ and +minitar-cli+\n    gems and discourages its installation.\n\nSome of these changes may break existing programs that depend on the internal\nstructure of the minitar library, but every effort has been made to ensure\ncompatibility; inasmuch as is possible, this compatibility will be maintained\nthrough the release of minitar 1.0 (which will have strong breaking changes).\n\nminitar (previously called Archive::Tar::Minitar) is based heavily on code\noriginally written by Mauricio Julio Fern\u{e1}ndez Pradier for the rpa-base\nproject."
  s.email = ["halostatue@gmail.com"]
  s.extra_rdoc_files = ["Code-of-Conduct.md", "Contributing.md", "History.md", "Licence.md", "Manifest.txt", "README.rdoc", "docs/bsdl.txt", "docs/ruby.txt"]
  s.files = ["Code-of-Conduct.md", "Contributing.md", "History.md", "Licence.md", "Manifest.txt", "README.rdoc", "Rakefile", "docs/bsdl.txt", "docs/ruby.txt", "lib/archive-tar-minitar.rb", "lib/archive/tar/minitar.rb", "lib/archive/tar/minitar/input.rb", "lib/archive/tar/minitar/output.rb", "lib/archive/tar/minitar/posix_header.rb", "lib/archive/tar/minitar/reader.rb", "lib/archive/tar/minitar/writer.rb", "lib/minitar.rb", "test/minitest_helper.rb", "test/support/tar_test_helpers.rb", "test/test_tar_header.rb", "test/test_tar_input.rb", "test/test_tar_output.rb", "test/test_tar_reader.rb", "test/test_tar_writer.rb"]
  s.homepage = "https://github.com/halostatue/minitar/"
  s.licenses = ["Ruby", "BSD-2-Clause"]
  s.post_install_message = "The `minitar` executable is no longer bundled with `minitar`. If you are\nexpecting this executable, make sure you also install `minitar-cli`.\n"
  s.rdoc_options = ["--main", "README.rdoc"]
  s.required_ruby_version = Gem::Requirement.new(">= 1.8")
  s.rubygems_version = "2.5.1"
  s.summary = "The minitar library is a pure-Ruby library that provides the ability to deal with POSIX tar(1) archive files"

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<minitest>, ["~> 5.10"])
      s.add_development_dependency(%q<hoe-doofus>, ["~> 1.0"])
      s.add_development_dependency(%q<hoe-gemspec2>, ["~> 1.1"])
      s.add_development_dependency(%q<hoe-git>, ["~> 1.6"])
      s.add_development_dependency(%q<hoe-rubygems>, ["~> 1.0"])
      s.add_development_dependency(%q<hoe-travis>, ["~> 1.2"])
      s.add_development_dependency(%q<minitest-autotest>, ["< 2", ">= 1.0"])
      s.add_development_dependency(%q<rake>, ["< 12", ">= 10.0"])
      s.add_development_dependency(%q<rdoc>, [">= 0.0"])
      s.add_development_dependency(%q<hoe>, ["~> 3.16"])
    else
      s.add_dependency(%q<minitest>, ["~> 5.10"])
      s.add_dependency(%q<hoe-doofus>, ["~> 1.0"])
      s.add_dependency(%q<hoe-gemspec2>, ["~> 1.1"])
      s.add_dependency(%q<hoe-git>, ["~> 1.6"])
      s.add_dependency(%q<hoe-rubygems>, ["~> 1.0"])
      s.add_dependency(%q<hoe-travis>, ["~> 1.2"])
      s.add_dependency(%q<minitest-autotest>, ["< 2", ">= 1.0"])
      s.add_dependency(%q<rake>, ["< 12", ">= 10.0"])
      s.add_dependency(%q<rdoc>, [">= 0.0"])
      s.add_dependency(%q<hoe>, ["~> 3.16"])
    end
  else
    s.add_dependency(%q<minitest>, ["~> 5.10"])
    s.add_dependency(%q<hoe-doofus>, ["~> 1.0"])
    s.add_dependency(%q<hoe-gemspec2>, ["~> 1.1"])
    s.add_dependency(%q<hoe-git>, ["~> 1.6"])
    s.add_dependency(%q<hoe-rubygems>, ["~> 1.0"])
    s.add_dependency(%q<hoe-travis>, ["~> 1.2"])
    s.add_dependency(%q<minitest-autotest>, ["< 2", ">= 1.0"])
    s.add_dependency(%q<rake>, ["< 12", ">= 10.0"])
    s.add_dependency(%q<rdoc>, [">= 0.0"])
    s.add_dependency(%q<hoe>, ["~> 3.16"])
  end
end
