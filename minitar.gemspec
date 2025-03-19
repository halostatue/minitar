# -*- encoding: utf-8 -*-
# stub: minitar 1.0.2 ruby lib

Gem::Specification.new do |s|
  s.name = "minitar".freeze
  s.version = "1.0.2".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/halostatue/minitar/issues", "homepage_uri" => "https://github.com/halostatue/minitar", "rubygems_mfa_required" => "true", "source_code_uri" => "https://github.com/halostatue/minitar/" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Austin Ziegler".freeze]
  s.date = "2025-03-19"
  s.description = "The minitar library is a pure-Ruby library that operates on POSIX tar(1) archive\nfiles.\n\nminitar (previously called Archive::Tar::Minitar) is based heavily on code\noriginally written by Mauricio Julio Fern\u00E1ndez Pradier for the rpa-base project.".freeze
  s.email = ["halostatue@gmail.com".freeze]
  s.extra_rdoc_files = ["CHANGELOG.md".freeze, "CODE_OF_CONDUCT.md".freeze, "CONTRIBUTING.md".freeze, "CONTRIBUTORS.md".freeze, "LICENCE.md".freeze, "Manifest.txt".freeze, "README.md".freeze, "SECURITY.md".freeze, "docs/bsdl.txt".freeze, "docs/ruby.txt".freeze]
  s.files = ["CHANGELOG.md".freeze, "CODE_OF_CONDUCT.md".freeze, "CONTRIBUTING.md".freeze, "CONTRIBUTORS.md".freeze, "LICENCE.md".freeze, "Manifest.txt".freeze, "README.md".freeze, "Rakefile".freeze, "SECURITY.md".freeze, "docs/bsdl.txt".freeze, "docs/ruby.txt".freeze, "lib/minitar.rb".freeze, "lib/minitar/input.rb".freeze, "lib/minitar/output.rb".freeze, "lib/minitar/posix_header.rb".freeze, "lib/minitar/reader.rb".freeze, "lib/minitar/version.rb".freeze, "lib/minitar/writer.rb".freeze, "test/minitest_helper.rb".freeze, "test/support/tar_test_helpers.rb".freeze, "test/test_issue_46.rb".freeze, "test/test_minitar.rb".freeze, "test/test_tar_header.rb".freeze, "test/test_tar_input.rb".freeze, "test/test_tar_output.rb".freeze, "test/test_tar_reader.rb".freeze, "test/test_tar_writer.rb".freeze]
  s.homepage = "https://github.com/halostatue/minitar".freeze
  s.licenses = ["Ruby".freeze, "BSD-2-Clause".freeze]
  s.rdoc_options = ["--main".freeze, "README.md".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.1".freeze)
  s.rubygems_version = "3.6.2".freeze
  s.summary = "The minitar library is a pure-Ruby library that operates on POSIX tar(1) archive files".freeze

  s.specification_version = 4

  s.add_development_dependency(%q<base64>.freeze, ["~> 0.2".freeze])
  s.add_development_dependency(%q<hoe>.freeze, ["~> 4.0".freeze])
  s.add_development_dependency(%q<hoe-halostatue>.freeze, ["~> 2.0".freeze])
  s.add_development_dependency(%q<hoe-rubygems>.freeze, ["~> 1.0".freeze])
  s.add_development_dependency(%q<minitest>.freeze, ["~> 5.16".freeze])
  s.add_development_dependency(%q<minitest-autotest>.freeze, ["~> 1.0".freeze])
  s.add_development_dependency(%q<minitest-focus>.freeze, ["~> 1.0".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 10.0".freeze, "< 14".freeze])
  s.add_development_dependency(%q<rdoc>.freeze, [">= 0.0".freeze])
  s.add_development_dependency(%q<standard>.freeze, ["~> 1.0".freeze])
  s.add_development_dependency(%q<standard-minitest>.freeze, ["~> 1.0".freeze])
  s.add_development_dependency(%q<standard-thread_safety>.freeze, ["~> 1.0".freeze])
end
