# frozen_string_literal: true

# The class that reads a tar format archive from a data stream. The data stream may be
# sequential or random access, but certain features only work with random access data
# streams.
class Minitar::Reader
  include Enumerable

  # This marks the EntryStream closed for reading without closing the actual data
  # stream.
  module InvalidEntryStream
    def read(*) = raise Minitar::ClosedStream # :nodoc:

    def getc = raise Minitar::ClosedStream # :nodoc:

    def rewind = raise Minitar::ClosedStream # :nodoc:

    def closed? = true # :nodoc:
  end

  # EntryStreams are pseudo-streams on top of the main data stream.
  class EntryStream
    Minitar::PosixHeader::FIELDS.each do |field|
      attr_reader field.to_sym
    end

    def initialize(header, io)
      @io = io
      @name = header.name
      @mode = header.mode
      @uid = header.uid
      @gid = header.gid
      @size = header.size
      @mtime = header.mtime
      @checksum = header.checksum
      @typeflag = header.typeflag
      @linkname = header.linkname
      @magic = header.magic
      @version = header.version
      @uname = header.uname
      @gname = header.gname
      @devmajor = header.devmajor
      @devminor = header.devminor
      @prefix = header.prefix
      @read = 0
      @orig_pos =
        if Minitar.seekable?(@io)
          @io.pos
        else
          0
        end
    end

    # Reads `len` bytes (or all remaining data) from the entry. Returns `nil` if there
    # is no more data to read.
    def read(len = nil)
      return nil if @read >= @size
      len ||= @size - @read
      max_read = [len, @size - @read].min
      ret = @io.read(max_read)
      @read += ret.bytesize
      ret
    end

    # Reads one byte from the entry. Returns `nil` if there is no more data to read.
    def getc
      return nil if @read >= @size
      ret = @io.getc
      @read += 1 if ret
      ret
    end

    # Returns `true` if the entry represents a directory.
    #
    # This is primarily controlled by #typeflag `5`, but if the #typeflag is `0` or `\0`,
    # filenames that end with a forward slash (`/`) will be treated as directories for
    # compatibility purposes.
    def directory?
      case @typeflag
      when "5"
        true
      when "0", "\0"
        @name.end_with?("/")
      else
        false
      end
    end
    alias_method :directory, :directory?

    # Returns `true` if the entry represents a plain file.
    def file?
      (@typeflag == "0" || @typeflag == "\0") && !@name.end_with?("/")
    end
    alias_method :file, :file?

    # Returns `true` if the current read pointer is at the end of the EntryStream data.
    def eof? = @read >= @size

    # Returns the current read pointer in the EntryStream.
    def pos = @read

    alias_method :bytes_read, :pos

    # Sets the current read pointer to the beginning of the EntryStream.
    def rewind
      unless Minitar.seekable?(@io, :pos=)
        raise Minitar::NonSeekableStream
      end
      @io.pos = @orig_pos
      @read = 0
    end

    # Returns the full and proper name of the entry.
    def full_name
      if @prefix != ""
        File.join(@prefix, @name)
      else
        @name
      end
    end

    # Returns false if the entry stream is valid.
    def closed? = false

    # Closes the entry.
    def close = invalidate

    private

    def invalidate
      extend InvalidEntryStream
    end
  end

  # With no associated block, Reader::open is a synonym for Reader::new. If the optional
  # code block is given, it will be passed the new _reader_ as an argument and the Reader
  # object will automatically be closed when the block terminates. In this
  # instance, Reader::open returns the value of the block.
  def self.open(io)
    reader = new(io)
    return reader unless block_given?

    # This exception context must remain, otherwise the stream closes on open even if
    # a block is not given.
    begin
      yield reader
    ensure
      reader.close
    end
  end

  # Iterates over each entry in the provided input. This wraps the common pattern of:
  #
  # ```ruby
  # Minitar::Input.open(io) do |i|
  #   inp.each do |entry|
  #     # ...
  #   end
  # end
  # ```
  #
  # If a block is not provided, an enumerator will be created with the same behaviour.
  #
  # :call-seq:
  #    Minitar::Reader.each_entry(io) -> enumerator
  #    Minitar::Reader.each_entry(io) { |entry| block } -> obj
  def self.each_entry(io)
    return to_enum(__method__, io) unless block_given?

    Input.open(io) do |reader|
      reader.each_entry do |entry|
        yield entry
      end
    end
  end

  # Creates and returns a new Reader object.
  def initialize(io)
    @io = io
    @init_pos = begin
      io.pos
    rescue
      nil
    end
  end

  # Resets the read pointer to the beginning of data stream. Do not call this during
  # a #each or #each_entry iteration. This only works with random access data streams that
  # respond to #rewind and #pos.
  def rewind
    if @init_pos.zero?
      raise Minitar::NonSeekableStream unless Minitar.seekable?(@io, :rewind)
      @io.rewind
    else
      raise Minitar::NonSeekableStream unless Minitar.seekable?(@io, :pos=)
      @io.pos = @init_pos
    end
  end

  # Iterates through each entry in the data stream.
  def each_entry
    return to_enum unless block_given?

    loop do
      return if @io.eof?

      header = Minitar::PosixHeader.from_stream(@io)
      raise Minitar::InvalidTarStream unless header.valid?
      return if header.empty?

      raise Minitar::InvalidTarStream if header.size < 0

      if header.long_name?
        name_block = (header.size / 512.0).ceil * 512

        long_name = @io.read(name_block).rstrip
        header = Minitar::PosixHeader.from_stream(@io)

        return if header.empty?
        header.long_name = long_name
      elsif header.pax_header?
        pax_header = Minitar::PaxHeader.from_stream(@io, header)

        header = Minitar::PosixHeader.from_stream(@io)
        return if header.empty?

        header.size = pax_header.size if pax_header.size
      end

      entry = EntryStream.new(header, @io)
      size = entry.size

      yield entry

      skip = (512 - (size % 512)) % 512

      if Minitar.seekable?(@io, :seek)
        # avoid reading...
        try_seek(size - entry.bytes_read)
      else
        pending = size - entry.bytes_read
        while pending > 0
          bread = @io.read([pending, 4096].min).bytesize
          raise Minitar::UnexpectedEOF if @io.eof?
          pending -= bread
        end
      end

      @io.read(skip) # discard trailing zeros
      # make sure nobody can use #read, #getc or #rewind anymore
      entry.close
    end
  end
  alias_method :each, :each_entry

  # Returns `false` if the reader is open (it never closes).
  def closed? = false

  def close = nil

  private

  def try_seek(bytes)
    @io.seek(bytes, IO::SEEK_CUR)
  rescue RangeError
    # This happens when skipping the large entry and the skipping entry size exceeds
    # maximum allowed size (varies by platform and underlying IO object).
    max = RbConfig::LIMITS.fetch("INT_MAX", 2147483647)
    skipped = 0
    while skipped < bytes
      to_skip = [bytes - skipped, max].min
      @io.seek(to_skip, IO::SEEK_CUR)
      skipped += to_skip
    end
  end
end
