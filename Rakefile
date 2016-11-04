# -*- ruby encoding: utf-8 -*-

require 'rubygems'
require 'hoe'
require 'rake/clean'

Hoe.plugin :doofus
Hoe.plugin :gemspec2
Hoe.plugin :git
Hoe.plugin :minitest
Hoe.plugin :travis
Hoe.plugin :email unless ENV['CI'] or ENV['TRAVIS']

spec = Hoe.spec 'minitar' do
  developer('Austin Ziegler', 'halostatue@gmail.com')

  self.require_ruby_version '>= 1.8'

  self.history_file = 'History.md'
  self.readme_file = 'README.rdoc'
  self.licenses = ["Ruby", "BSD-2-Clause"]

  extra_dev_deps << ['hoe-doofus', '~> 1.0']
  extra_dev_deps << ['hoe-gemspec2', '~> 1.1']
  extra_dev_deps << ['hoe-git', '~> 1.6']
  extra_dev_deps << ['hoe-rubygems', '~> 1.0']
  extra_dev_deps << ['hoe-travis', '~> 1.2']
  extra_dev_deps << ['minitest', '~> 5.3']
  extra_dev_deps << ['minitest-autotest', ['>= 1.0.b', '<2']]
  extra_dev_deps << ['rake', '~> 10.0']
end

if RUBY_VERSION >= "2.0"
  namespace :test do
    task :coveralls do
      spec.test_prelude = [
        'require "psych"',
        'require "simplecov"',
        'require "coveralls"',
        'SimpleCov.formatter = Coveralls::SimpleCov::Formatter',
        'SimpleCov.start("test_frameworks") { command_name "Minitest" }',
        'gem "minitest"'
      ].join('; ')
      Rake::Task['test'].execute
    end

    desc 'Run test coverage'
    task :coverage do
      spec.test_prelude = [
        'require "simplecov"',
        'SimpleCov.start("test_frameworks") { command_name "Minitest" }',
        'gem "minitest"'
      ].join('; ')
      Rake::Task['test'].execute
    end
  end

  Rake::Task['travis'].prerequisites.replace(%w(test:coveralls))
end
