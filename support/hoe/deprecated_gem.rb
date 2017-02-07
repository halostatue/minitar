
# A Hoe plug-in to provide a second, linked gemspec, for a gem that has been
# deprecated in favour of a modern name. (The name is an artifact of Hoe's
# plugin loading.)
module Hoe::Deprecated_Gem # rubocop:disable Style/ClassAndModuleCamelCase
  def linked_spec(spec)
    atm = YAML.load(YAML.dump(spec))
    atm.name = 'archive-tar-minitar'
    d = %Q('#{atm.name}' has been deprecated; just install '#{spec.name}'.)
    atm.description = "#{d} #{spec.description}"
    atm.summary = atm.post_install_message = d
    atm.files.delete_if do |f|
      f !~ %r{lib/archive-tar-minitar\.rb}
    end
    atm.extra_rdoc_files.clear
    atm.rdoc_options.clear
    atm.dependencies.clear
    atm.add_dependency(spec.name, "~> #{spec.version}")
    atm.add_dependency(%Q(#{spec.name}-cli), '<= 1.0')

    unless @include_all
      [ :signing_key, :cert_chain ].each { |name|
        atm.send("#{name}=".to_sym, atm.default_value(name))
      }
    end

    atm
  end

  def define_deprecated_gem_tasks
    gemspec = spec.name + '.gemspec'
    atmspec = 'archive-tar-minitar.gemspec'

    file atmspec => gemspec do
      open(atmspec, 'w') { |f| f.write(linked_spec(spec).to_ruby) }
    end

    task :gemspec => atmspec

    Gem::PackageTask.new linked_spec(spec) do |pkg|
      pkg.need_tar = @need_tar
      pkg.need_zip = @need_zip
    end
  end
end
