#!/usr/bin/env ruby

require 'minitar'
require 'minitest_helper'

class TestTarOutput < Minitest::Test
  def setup
    FileUtils.mkdir_p('data__')
    %w(a b c).each do |filename|
      name = File.join('data__', filename)
      File.open(name, 'wb') { |f|
        f.puts "#{name}: 123456789012345678901234567890"
      }
    end
    @tarfile = 'data__/bla2.tar'
  end

  def teardown
    FileUtils.rm_rf('data__')
  end

  def test_open_no_block
    output = Minitar::Output.open(@tarfile)
    refute output.closed?
  ensure
    output.close
    assert output.closed?
  end

  def test_file_looks_good
    Minitar::Output.open(@tarfile) do |os|
      Dir.chdir('data__') do
        %w(a b c).each do |name|
          stat = File.stat(name)
          opts = { :size => stat.size, :mode => 0o644 }
          os.tar.add_file_simple(name, opts) do |ss|
            File.open(name, 'rb') { |ff| ss.write(ff.read(4096)) until ff.eof? }
          end
        end
      end
    end
    ff = File.open(@tarfile, 'rb')
    Minitar::Reader.open(ff) do |is|
      ii = 0
      is.each do |entry|
        case ii
        when 0
          assert_equal('a', entry.name)
        when 1
          assert_equal('b', entry.name)
        when 2
          assert_equal('c', entry.name)
        end
        ii += 1
      end
      assert_equal(3, ii)
    end
  ensure
    ff.close if ff
  end
end
