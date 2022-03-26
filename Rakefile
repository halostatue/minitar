# -*- ruby encoding: utf-8 -*-

require "rubygems"
require "hoe"
require "rake/clean"

$LOAD_PATH.unshift("support")

# This is required until https://github.com/seattlerb/hoe/issues/112 is fixed
class Hoe
  def with_config
    config = Hoe::DEFAULT_CONFIG

    rc = File.expand_path("~/.hoerc")
    homeconfig = load_config(rc)
    config = config.merge(homeconfig)

    localconfig = load_config(File.expand_path(File.join(Dir.pwd, ".hoerc")))
    config = config.merge(localconfig)

    yield config, rc
  end

  def load_config(name)
    File.exist?(name) ? safe_load_yaml(name) : {}
  end

  def safe_load_yaml(name)
    return safe_load_yaml_file(name) if YAML.respond_to?(:safe_load_file)

    data = IO.binread(name)
    YAML.safe_load(data, permitted_classes: [Regexp])
  rescue
    YAML.safe_load(data, [Regexp])
  end

  def safe_load_yaml_file(name)
    YAML.safe_load_file(name, permitted_classes: [Regexp])
  rescue
    YAML.safe_load_file(name, [Regexp])
  end
end

Hoe.plugin :doofus
Hoe.plugin :gemspec2
Hoe.plugin :git
Hoe.plugin :minitest
Hoe.plugin :deprecated_gem
Hoe.plugin :email unless ENV["CI"]

spec = Hoe.spec "minitar" do
  developer("Austin Ziegler", "halostatue@gmail.com")

  require_ruby_version ">= 1.8"

  self.history_file = "History.md"
  self.readme_file = "README.rdoc"
  self.licenses = ["Ruby", "BSD-2-Clause"]

  self.post_install_message = <<-EOS
The `minitar` executable is no longer bundled with `minitar`. If you are
expecting this executable, make sure you also install `minitar-cli`.
  EOS

  extra_dev_deps << ["hoe-doofus", "~> 1.0"]
  extra_dev_deps << ["hoe-gemspec2", "~> 1.1"]
  extra_dev_deps << ["hoe-git", "~> 1.6"]
  extra_dev_deps << ["hoe-rubygems", "~> 1.0"]
  extra_dev_deps << ["standard", "~> 1.0"]
  extra_dev_deps << ["minitest", "~> 5.3"]
  extra_dev_deps << ["minitest-autotest", [">= 1.0", "<2"]]
  extra_dev_deps << ["rake", ">= 10.0", "< 14"]
  extra_dev_deps << ["rdoc", ">= 0.0"]
end

if RUBY_VERSION >= "2.0" && RUBY_ENGINE == "ruby" && !ENV["CI"]
  namespace :test do
    desc "Run test coverage"
    task :coverage do
      spec.test_prelude = 'load ".simplecov-prelude.rb"'
      Rake::Task["test"].execute
    end
  end
end
