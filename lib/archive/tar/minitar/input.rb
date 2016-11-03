# coding: utf-8

require 'archive/tar/minitar/reader'

module Archive::Tar::Minitar
  # Wraps a Archive::Tar::Minitar::Reader with convenience methods and wrapped
  # stream management; Input only works with data streams that can be rewound.
  class Input
    include Enumerable

    # With no associated block, +Input.open+ is a synonym for +Input.new+. If
    # the optional code block is given, it will be given the new Input as an
    # argument and the Input object will automatically be closed when the block
    # terminates (this also closes the wrapped stream object). In this
    # instance, +Input.open+ returns the value of the block.
    #
    # call-seq:
    #    Archive::Tar::Minitar::Input.open(io) -> input
    #    Archive::Tar::Minitar::Input.open(io) { |input| block } -> obj
    def self.open(input)
      stream = new(input)
      return stream unless block_given?

      begin
        res = yield stream
      ensure
        stream.close
      end

      res
    end

    # Creates a new Input object. If +input+ is a stream object that responds
    # to #read, then it will simply be wrapped. Otherwise, one will be created
    # and opened using Kernel#open. When Input#close is called, the stream
    # object wrapped will be closed.
    #
    # An exception will be raised if the stream that is wrapped does not
    # support rewinding.
    #
    # call-seq:
    #    Archive::Tar::Minitar::Input.new(io) -> input
    #    Archive::Tar::Minitar::Input.new(path) -> input
    def initialize(input)
      if input.respond_to?(:read)
        @io = input
      else
        @io = ::Kernel.open(input, "rb")
      end

      unless Archive::Tar::Minitar.seekable?(@io, :rewind)
        raise Archive::Tar::Minitar::NonSeekableStream
      end

      @tar = Reader.new(@io)
    end

    # When provided a block, iterates through each entry in the archive. When
    # finished, rewinds to the beginning of the stream.
    #
    # If not provided a block, creates an enumerator with the same semantics.
    def each
      if block_given?
        begin
          @tar.each { |entry| yield entry }
        ensure
          @tar.rewind
        end
      else
        enum_for(:each)
      end
    end

    # Extracts the current +entry+ to +destdir+. If a block is provided, it
    # yields an +action+ Symbol, the full name of the file being extracted
    # (+name+), and a Hash of statistical information (+stats+).
    #
    # The +action+ will be one of:
    # <tt>:dir</tt>::           The +entry+ is a directory.
    # <tt>:file_start</tt>::    The +entry+ is a file; the extract of the
    #                           file is just beginning.
    # <tt>:file_progress</tt>:: Yielded every 4096 bytes during the extract
    #                           of the +entry+.
    # <tt>:file_done</tt>::     Yielded when the +entry+ is completed.
    #
    # The +stats+ hash contains the following keys:
    # <tt>:current</tt>:: The current total number of bytes read in the
    #                     +entry+.
    # <tt>:currinc</tt>:: The current number of bytes read in this read
    #                     cycle.
    # <tt>:entry</tt>::   The entry being extracted; this is a
    #                     Reader::EntryStream, with all methods thereof.
    def extract_entry(destdir, entry) # :yields action, name, stats:
      stats = {
        :current  => 0,
        :currinc  => 0,
        :entry    => entry
      }

      if entry.directory?
        dest = File.join(destdir, entry.full_name)

        yield :dir, entry.full_name, stats if block_given?

        if Archive::Tar::Minitar.dir?(dest)
          begin
            FileUtils.chmod(entry.mode, dest)
          rescue Exception
            nil
          end
        else
          FileUtils.mkdir_p(dest, :mode => entry.mode)
          FileUtils.chmod(entry.mode, dest)
        end

        fsync_dir(dest)
        fsync_dir(File.join(dest, ".."))
        return
      else # it's a file
        destdir = File.join(destdir, File.dirname(entry.full_name))
        FileUtils.mkdir_p(destdir, :mode => 0755)

        destfile = File.join(destdir, File.basename(entry.full_name))
        FileUtils.chmod(0600, destfile) rescue nil  # Errno::ENOENT

        yield :file_start, entry.full_name, stats if block_given?

        File.open(destfile, "wb", entry.mode) do |os|
          loop do
            data = entry.read(4096)
            break unless data

            stats[:currinc] = os.write(data)
            stats[:current] += stats[:currinc]

            yield :file_progress, entry.full_name, stats if block_given?
          end
          os.fsync
        end

        FileUtils.chmod(entry.mode, destfile)
        fsync_dir(File.dirname(destfile))
        fsync_dir(File.join(File.dirname(destfile), ".."))

        yield :file_done, entry.full_name, stats if block_given?
      end
    end

    # Returns the Reader object for direct access.
    attr_reader :tar

    # Closes both the Reader object and the wrapped data stream.
    def close
      @io.close
      @tar.close
    end

    private

    def fsync_dir(dirname)
      # make sure this hits the disc
      dir = open(dirname, 'rb')
      dir.fsync
    rescue # ignore IOError if it's an unpatched (old) Ruby
      nil
    ensure
      dir.close if dir rescue nil
    end
  end
end
