# frozen_string_literal: true

require "minitest_helper"

class TestMinitar < Minitest::Test
  SCENARIO = {
    "path" => nil,
    "test" => "test",
    "extra/test" => "extra/test",
    "empty2004" => {mtime: TIME_2004, mode: 0o755, data: ""},
    "notime" => {mtime: nil, data: "notime"}
  }

  def test_minitar_open_r
    count = 0

    open_fixture("test_minitar") do |fixture|
      Minitar.open(fixture, "r") do |stream|
        stream.each do |entry|
          assert_kind_of Minitar::Reader::EntryStream, entry

          assert SCENARIO.has_key?(entry.name), "#{entry.name} not expected"

          expected = SCENARIO[entry.name]

          case expected
          when nil
            assert_equal 0, entry.size
            assert_modes_equal 0o755, entry.mode, entry.name
            assert entry.directory?, "#{entry.name} should be a directory"
          when String
            assert_equal expected.length, entry.size, entry.name
            assert_modes_equal 0o644, entry.mode, entry.name
            assert entry.file?, "#{entry.name} should be a file"

            if entry.size.zero?
              assert_nil entry.read
            else
              assert_equal expected, entry.read
            end
          when Hash
            if expected[:data].nil?
              assert_equal 0, entry.size
              assert_modes_equal (expected[:mode] || 0o755), entry.mode, entry.name
              assert entry.directory?, "#{entry.name} should be a directory"
            else
              assert_equal expected[:data].length, entry.size
              assert_modes_equal (expected[:mode] || 0o644), entry.mode, entry.name
              assert entry.file?, "#{entry.name} should be a file"
            end

            assert_equal expected[:mtime], entry.mtime if expected[:mtime]

            if entry.size.zero?
              assert_nil entry.read
            else
              assert_equal expected[:data], entry.read
            end
          end

          count += 1
        end
      end
    end

    assert_equal SCENARIO.size, count
  end

  def test_minitar_open_w
    events = []

    writer = StringIO.new
    Minitar.open(writer, "w") do |stream|
      SCENARIO.each_pair do |name, data|
        name, data =
          if data.is_a?(Hash)
            name = data.merge(name: name)
            [name, name.delete(:data)]
          else
            [name, data]
          end

        Minitar.pack_as_file(name, data, stream) do |op, entry_name, stats|
          events << {
            name: name,
            data: data,
            op: op,
            entry_name: entry_name,
            stats: stats
          }
        end
      end
    end

    assert_equal 5120, writer.string.length

    events.each do |event|
      if event[:name].is_a?(Hash)
        assert_equal event[:name][:name], event[:entry_name]
      else
        assert_equal event[:name], event[:entry_name]
      end

      case [event[:op], event[:entry_name]]
      in [:dir, "path"]
        assert_equal 0, event[:stats][:size]
        assert_equal 493, event[:stats][:mode]

      in [:file_start, "test"]
        assert_equal 4, event[:stats][:size]
        assert_equal 420, event[:stats][:mode]
        assert_equal 4, event[:stats][:current]
        assert_equal 4, event[:stats][:currinc]
        assert_equal "test", event[:data]
      in [:file_progress, "test"]
        assert_equal 4, event[:stats][:size]
        assert_equal 420, event[:stats][:mode]
        assert_equal 4, event[:stats][:current]
        assert_equal 4, event[:stats][:currinc]
        assert_equal "test", event[:data]
      in [:file_done, "test"]
        assert_equal 4, event[:stats][:size]
        assert_equal 420, event[:stats][:mode]
        assert_equal 4, event[:stats][:current]
        assert_equal 4, event[:stats][:currinc]
        assert_equal "test", event[:data]

      in [:file_start, "extra/test"]
        assert_equal 10, event[:stats][:size]
        assert_equal 420, event[:stats][:mode]
        assert_equal 10, event[:stats][:current]
        assert_equal 10, event[:stats][:currinc]
        assert_equal "extra/test", event[:data]
      in [:file_progress, "extra/test"]
        assert_equal 10, event[:stats][:size]
        assert_equal 420, event[:stats][:mode]
        assert_equal 10, event[:stats][:current]
        assert_equal 10, event[:stats][:currinc]
        assert_equal "extra/test", event[:data]
      in [:file_done, "extra/test"]
        assert_equal 10, event[:stats][:size]
        assert_equal 420, event[:stats][:mode]
        assert_equal 10, event[:stats][:current]
        assert_equal 10, event[:stats][:currinc]
        assert_equal "extra/test", event[:data]

      in [:file_start, "empty2004"]
        assert_equal 0, event[:stats][:size]
        assert_equal 493, event[:stats][:mode]
        assert_equal 0, event[:stats][:current]
        assert_equal 1072915200, event[:stats][:mtime]
        assert_equal "", event[:data]
      in [:file_done, "empty2004"]
        assert_equal 0, event[:stats][:size]
        assert_equal 493, event[:stats][:mode]
        assert_equal 0, event[:stats][:current]
        assert_equal 1072915200, event[:stats][:mtime]
        assert_equal "", event[:data]

      in [:file_start, "notime"]
        assert_equal 6, event[:stats][:size]
        assert_equal 420, event[:stats][:mode]
        assert_equal 6, event[:stats][:current]
        assert_equal 6, event[:stats][:currinc]
        assert_equal "notime", event[:data]
      in [:file_progress, "notime"]
        assert_equal 6, event[:stats][:size]
        assert_equal 420, event[:stats][:mode]
        assert_equal 6, event[:stats][:current]
        assert_equal 6, event[:stats][:currinc]
        assert_equal "notime", event[:data]
      in [:file_done, "notime"]
        assert_equal 6, event[:stats][:size]
        assert_equal 420, event[:stats][:mode]
        assert_equal 6, event[:stats][:current]
        assert_equal 6, event[:stats][:currinc]
        assert_equal "notime", event[:data]
      else
        raise "Unknown operation #{event[:op].inspect} for #{event[:entry_name].inspect}"
      end
    end
  end

  def test_minitar_x
    assert_raises(ArgumentError) do
      Minitar.open("foo", "x")
    end
  end
end
