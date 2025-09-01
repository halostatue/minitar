# frozen_string_literal: true

module Minitar::TestHelpers::Fixtures
  def Fixture(name) = FIXTURES.fetch(name)

  def open_fixture(name)
    fixture = Fixture(name)

    io = fixture.open("rb").then {
      if %w[.gz .tgz].include?(fixture.extname.to_s)
        Zlib::GzipReader.new(_1)
      else
        _1
      end
    }.tap {
      yield _1 if block_given?
    }
  ensure
    io&.close if block_given?
  end

  FIXTURES = Pathname(__dir__)
    .join("../../fixtures")
    .expand_path
    .glob("**")
    .each_with_object({}) {
      next if _1.directory?

      name = _1.dup
      name = name.basename(name.extname) until name.nil? || name.extname.empty?

      _2[name.to_s] = _1
    }
    .freeze
  private_constant :FIXTURES

  Minitest::Test.send(:include, self)
end
