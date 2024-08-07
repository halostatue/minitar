# -*- encoding: utf-8 -*-
# stub: minitar 1.0.0 ruby lib

Gem::Specification.new do |s|
  s.name = "minitar".freeze
  s.version = "1.0.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/halostatue/minitar/issues", "homepage_uri" => "https://github.com/halostatue/minitar/", "rubygems_mfa_required" => "true", "source_code_uri" => "https://github.com/halostatue/minitar/" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Austin Ziegler".freeze]
  s.date = "2024-08-07"
  s.description = "The minitar library is a pure-Ruby library that provides the ability to deal\nwith POSIX tar(1) archive files.\n\nThis is release 0.12. This is likely the last revision before 1.0.\n\nminitar (previously called Archive::Tar::Minitar) is based heavily on code\noriginally written by Mauricio Julio Fern\u00E1ndez Pradier for the rpa-base\nproject.".freeze
  s.email = ["halostatue@gmail.com".freeze]
  s.extra_rdoc_files = ["Code-of-Conduct.md".freeze, "Contributing.md".freeze, "History.md".freeze, "Licence.md".freeze, "Manifest.txt".freeze, "README.rdoc".freeze, "docs/bsdl.txt".freeze, "docs/ruby.txt".freeze]
  s.files = ["Code-of-Conduct.md".freeze, "Contributing.md".freeze, "History.md".freeze, "Licence.md".freeze, "Manifest.txt".freeze, "README.rdoc".freeze, "Rakefile".freeze, "docs/bsdl.txt".freeze, "docs/ruby.txt".freeze, "lib/minitar.rb".freeze, "lib/minitar/input.rb".freeze, "lib/minitar/output.rb".freeze, "lib/minitar/posix_header.rb".freeze, "lib/minitar/reader.rb".freeze, "lib/minitar/writer.rb".freeze, "test/minitest_helper.rb".freeze, "test/support/tar_test_helpers.rb".freeze, "test/test_issue_46.rb".freeze, "test/test_tar_header.rb".freeze, "test/test_tar_input.rb".freeze, "test/test_tar_output.rb".freeze, "test/test_tar_reader.rb".freeze, "test/test_tar_writer.rb".freeze]
  s.homepage = "https://github.com/halostatue/minitar/".freeze
  s.licenses = ["Ruby".freeze, "BSD-2-Clause".freeze]
  s.rdoc_options = ["--main".freeze, "README.rdoc".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.1".freeze)
  s.rubygems_version = "3.5.17".freeze
  s.summary = "The minitar library is a pure-Ruby library that provides the ability to deal with POSIX tar(1) archive files".freeze

  s.specification_version = 4

  s.add_development_dependency(%q<minitest>.freeze, ["~> 5.24".freeze])
  s.add_development_dependency(%q<base64>.freeze, ["~> 0.2".freeze])
  s.add_development_dependency(%q<hoe>.freeze, ["~> 4.0".freeze])
  s.add_development_dependency(%q<hoe-doofus>.freeze, ["~> 1.0".freeze])
  s.add_development_dependency(%q<hoe-gemspec2>.freeze, ["~> 1.1".freeze])
  s.add_development_dependency(%q<hoe-git2>.freeze, ["~> 1.7".freeze])
  s.add_development_dependency(%q<hoe-rubygems>.freeze, ["~> 1.0".freeze])
  s.add_development_dependency(%q<minitest-autotest>.freeze, ["~> 1.0".freeze])
  s.add_development_dependency(%q<minitest-focus>.freeze, ["~> 1.0".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 10.0".freeze, "< 14".freeze])
  s.add_development_dependency(%q<rdoc>.freeze, [">= 0.0".freeze])
  s.add_development_dependency(%q<standard>.freeze, ["~> 1.0".freeze])
  s.add_development_dependency(%q<standard-minitest>.freeze, ["~> 1.0".freeze])
  s.add_development_dependency(%q<standard-thread_safety>.freeze, ["~> 1.0".freeze])
  s.add_development_dependency(%q<simplecov>.freeze, ["~> 0.21".freeze])
end
