# -*- encoding: utf-8 -*-
# stub: archive-tar-minitar 0.6 ruby lib

minitar = Gem::Specification.load('minitar.gemspec')
minitar.name = 'archive-tar-minitar'
minitar.description =
  minitar.summary = %q(This gem is deprecated. Just install 'minitar'.)
minitar.files.delete_if { |f| f !~ %r{lib/archive-tar-minitar\.rb} }
minitar.extra_rdoc_files.clear
minitar.rdoc_options.clear
minitar.dependencies.clear
minitar.add_dependency(%q<minitar>, "~> #{minitar.version}")
minitar.add_dependency(%q<minitar-cli>, "<= 1.0")

minitar
