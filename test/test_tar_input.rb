#!/usr/bin/env ruby

require 'minitar'
require 'minitest_helper'
require 'base64'
require 'zlib'

class TestTarInput < Minitest::Test
  include TarTester

  TEST_TGZ = Base64.decode64 <<-EOS
H4sIAKJpllQAA0tJLEnUK0ks0kuvYqAVMDAwMDMxUQDR5mbmYNrACMIHA2MjIwUDc3NzEzMz
QxMDAwUDQ2NTczMGBQOauQgJlBYDfQ90SiKQkZmHWx1QWVoaHnMgXlGA00MEyHdzMMzOnBbC
wPz28n2uJgOR44Xrq7tsHc/utNe/9FdihkmH3pZ7+zOTRFREzkzYJ99iHHDn4n0/Wb3E8Ceq
S0uOdSyMMg9Z+WVvX0vJucxs77vrvZf2arWcvHP9wa1Yp9lRnJmC59/P9+43PXum+tj7Ga+8
rtT+u3d941e765Y/bOrnvpv8X6jtz+wKqyk/v3n8P5xlO3l/1dn9q9Zotpy5funw/Of77Y/5
LVltz7ToTl7dXf5ppmf3n9p+PPxz/sz/qjZn9yf9Y4R7I2Ft3tqfPTUMGgMYlEMSpGXmpBrT
2A5Qvjc1xZ3/DTDyv5GJmfFo/qcHCMnILFYAIlA6UDDWU+DlGmgXjYJRMApGwSgYBaNgFIyC
UTAKRsEoGAWjYBSMglEwCkbBKBgFo2AUjIJRMApGwSgYBaNgFIwCUgAAGnyo6wAoAAA=
  EOS
  FILETIMES = Time.utc(2004).to_i

  TEST_CONTENTS = {
    "data.tar.gz" => { :size => 210, :mode => 0644 },
    "file3" => { :size => 18, :mode => 0755 },
  }

  TEST_DATA_CONTENTS = {
    "data/" => { :size => 0, :mode => 0755 },
    "data/__dir__/" => { :size => 0, :mode => 0755 },
    "data/file1" => { :size => 16, :mode => 0644 },
    "data/file2" => { :size => 16, :mode => 0644 },
  }

  def setup
    FileUtils.mkdir_p("data__")
  end

  def teardown
    FileUtils.rm_rf("data__")
  end

  def test_each_works
    reader = Zlib::GzipReader.new(StringIO.new(TEST_TGZ))
    Minitar::Input.open(reader) do |stream|
      outer = 0
      stream.each.with_index do |entry, i|
        assert_kind_of(Minitar::Reader::EntryStream, entry)
        assert TEST_CONTENTS.has_key?(entry.name)

        assert_equal(TEST_CONTENTS[entry.name][:size], entry.size, entry.name)
        assert_modes_equal(TEST_CONTENTS[entry.name][:mode],
                           entry.mode, entry.name)
        assert_equal(FILETIMES, entry.mtime, "entry.mtime")

        if i.zero?
          data_reader = Zlib::GzipReader.new(StringIO.new(entry.read))
          Minitar::Input.open(data_reader) do |is2|
            inner = 0
            is2.each_with_index do |entry2, j|
              assert_kind_of(Minitar::Reader::EntryStream, entry2)
              assert TEST_DATA_CONTENTS.has_key?(entry2.name)
              assert_equal(TEST_DATA_CONTENTS[entry2.name][:size], entry2.size,
                           entry2.name)
              assert_modes_equal(TEST_DATA_CONTENTS[entry2.name][:mode],
                                 entry2.mode, entry2.name)
              assert_equal(FILETIMES, entry2.mtime, entry2.name)
              inner += 1
            end
            assert_equal(4, inner)
          end
        end

        outer += 1
      end
      assert_equal(2, outer)
    end
  end

  def test_extract_entry_works
    reader = Zlib::GzipReader.new(StringIO.new(TEST_TGZ))
    Minitar::Input.open(reader) do |stream|
      outer_count = 0
      stream.each_with_index do |entry, i|
        stream.extract_entry("data__", entry)
        name = File.join("data__", entry.name)

        assert TEST_CONTENTS.has_key?(entry.name)

        if entry.directory?
          assert(File.directory?(name))
        else
          assert(File.file?(name))

          assert_equal(TEST_CONTENTS[entry.name][:size], File.stat(name).size)
        end

        assert_modes_equal(TEST_CONTENTS[entry.name][:mode],
                           File.stat(name).mode, entry.name)

        if i.zero?
          begin
            ff    = File.open(name, "rb")
            data_reader  = Zlib::GzipReader.new(ff)
            Minitar::Input.open(data_reader) do |is2|
              is2.each_with_index do |entry2, j|
                is2.extract_entry("data__", entry2)
                name2 = File.join("data__", entry2.name)

                assert TEST_DATA_CONTENTS.has_key?(entry2.name)

                if entry2.directory?
                  assert(File.directory?(name2))
                else
                  assert(File.file?(name2))
                  assert_equal(TEST_DATA_CONTENTS[entry2.name][:size],
                               File.stat(name2).size)
                end
                assert_modes_equal(TEST_DATA_CONTENTS[entry2.name][:mode],
                                   File.stat(name2).mode, name2)
              end
            end
          ensure
            ff.close unless ff.closed?
          end
        end

        outer_count += 1
      end

      assert_equal(2, outer_count)
    end
  end
end
