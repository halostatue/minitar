# -*- encoding: utf-8 -*-
# stub: archive-tar-minitar 0.7 ruby lib

Gem::Specification.new do |s|
  s.name = "archive-tar-minitar".freeze
  s.version = "0.7"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Austin Ziegler".freeze]
  s.date = "2018-10-28"
  s.description = "'archive-tar-minitar' has been deprecated; just install 'minitar'. The minitar library is a pure-Ruby library that provides the ability to deal\nwith POSIX tar(1) archive files.\n\nThis is release 0.7, providing fixes for several issues and clarifying the\nMinitar security stance. There are two minor breaking changes in this version\nso that exceptions will be thrown if a negative size is provided in a tar\nstream header or if the tar stream header is otherwise invalid.\n\nThis release continues the migration and modernization of the code:\n\n*   the licence has been changed to match the modern Ruby licensing scheme\n    (Ruby and Simplified BSD instead of Ruby and GNU GPL);\n*   the +minitar+ command-line program has been separated into the\n    +minitar-cli+ gem; and\n*   the +archive-tar-minitar+ gem now points to the +minitar+ and +minitar-cli+\n    gems and discourages its installation.\n\nSome of these changes may break existing programs that depend on the internal\nstructure of the minitar library, but every effort has been made to ensure\ncompatibility; inasmuch as is possible, this compatibility will be maintained\nthrough the release of minitar 1.0 (which will have strong breaking changes).\n\nminitar (previously called Archive::Tar::Minitar) is based heavily on code\noriginally written by Mauricio Julio Fern\u00E1ndez Pradier for the rpa-base\nproject.".freeze
  s.email = ["halostatue@gmail.com".freeze]
  s.files = ["lib/archive-tar-minitar.rb".freeze]
  s.homepage = "https://github.com/halostatue/minitar/".freeze
  s.licenses = ["Ruby".freeze, "BSD-2-Clause".freeze]
  s.post_install_message = "'archive-tar-minitar' has been deprecated; just install 'minitar'.".freeze
  s.required_ruby_version = Gem::Requirement.new(">= 1.8".freeze)
  s.rubygems_version = "2.7.7".freeze
  s.summary = "'archive-tar-minitar' has been deprecated; just install 'minitar'.".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<minitar>.freeze, ["~> 0.7"])
      s.add_runtime_dependency(%q<minitar-cli>.freeze, ["~> 0.6"])
    else
      s.add_dependency(%q<minitar>.freeze, ["~> 0.7"])
      s.add_dependency(%q<minitar-cli>.freeze, ["~> 0.6"])
    end
  else
    s.add_dependency(%q<minitar>.freeze, ["~> 0.7"])
    s.add_dependency(%q<minitar-cli>.freeze, ["~> 0.6"])
  end
end
