# coding: utf-8

module Archive
  module Tar
    module Minitar
      # The class that reads a tar format archive from a data stream. The data
      # stream may be sequential or random access, but certain features only work
      # with random access data streams.
      class Reader
        # This marks the EntryStream closed for reading without closing the
        # actual data stream.
        module InvalidEntryStream
          def read(len = nil); raise ClosedStream; end
          def getc; raise ClosedStream;  end
          def rewind; raise ClosedStream;  end
        end

        # EntryStreams are pseudo-streams on top of the main data stream.
        class EntryStream
          PosixHeader::FIELDS.each do |field|
            attr_reader field.to_sym
          end

          def initialize(header, anIO)
            @io       = anIO
            @name     = header.name
            @mode     = header.mode
            @uid      = header.uid
            @gid      = header.gid
            @size     = header.size
            @mtime    = header.mtime
            @checksum = header.checksum
            @typeflag = header.typeflag
            @linkname = header.linkname
            @magic    = header.magic
            @version  = header.version
            @uname    = header.uname
            @gname    = header.gname
            @devmajor = header.devmajor
            @devminor = header.devminor
            @prefix   = header.prefix
            @read     = 0
            @orig_pos = if Archive::Tar::Minitar.seekable?(@io)
                          @io.pos
                        else
                          0
                        end
          end

          # Reads +len+ bytes (or all remaining data) from the entry. Returns
          # +nil+ if there is no more data to read.
          def read(len = nil)
            return nil if @read >= @size
            len ||= @size - @read
            max_read = [len, @size - @read].min
            ret = @io.read(max_read)
            @read += ret.size
            ret
          end

          # Reads one byte from the entry. Returns +nil+ if there is no more data
          # to read.
          def getc
            return nil if @read >= @size
            ret = @io.getc
            @read += 1 if ret
            ret
          end

          # Returns +true+ if the entry represents a directory.
          def directory?
            @typeflag == "5"
          end
          alias_method :directory, :directory?

          # Returns +true+ if the entry represents a plain file.
          def file?
            @typeflag == "0"
          end
          alias_method :file, :file?

          # Returns +true+ if the current read pointer is at the end of the
          # EntryStream data.
          def eof?
            @read >= @size
          end

          # Returns the current read pointer in the EntryStream.
          def pos
            @read
          end

          # Sets the current read pointer to the beginning of the EntryStream.
          def rewind
            unless Archive::Tar::Minitar.seekable?(@io, :pos=)
              raise Archive::Tar::Minitar::NonSeekableStream
            end
            @io.pos = @orig_pos
            @read = 0
          end

          def bytes_read
            @read
          end

          # Returns the full and proper name of the entry.
          def full_name
            if @prefix != ""
              File.join(@prefix, @name)
            else
              @name
            end
          end

          # Closes the entry.
          def close
            invalidate
          end

          private
          def invalidate
            extend InvalidEntryStream
          end
        end

        # With no associated block, +Reader::open+ is a synonym for
        # +Reader::new+. If the optional code block is given, it will be passed
        # the new _writer_ as an argument and the Reader object will
        # automatically be closed when the block terminates. In this instance,
        # +Reader::open+ returns the value of the block.
        def self.open(anIO)
          reader = new(anIO)

          return reader unless block_given?

          begin
            res = yield reader
          ensure
            reader.close
          end

          res
        end

        # Creates and returns a new Reader object.
        def initialize(anIO)
          @io     = anIO
          @init_pos = anIO.pos
        end

        # Iterates through each entry in the data stream.
        def each(&block)
          each_entry(&block)
        end

        # Resets the read pointer to the beginning of data stream. Do not call
        # this during a #each or #each_entry iteration. This only works with
        # random access data streams that respond to #rewind and #pos.
        def rewind
          if @init_pos == 0
            unless Archive::Tar::Minitar.seekable?(@io, :rewind)
              raise Archive::Tar::Minitar::NonSeekableStream
            end
            @io.rewind
          else
            unless Archive::Tar::Minitar.seekable?(@io, :pos=)
              raise Archive::Tar::Minitar::NonSeekableStream
            end
            @io.pos = @init_pos
          end
        end

        # Iterates through each entry in the data stream.
        def each_entry
          loop do
            return if @io.eof?

            header = PosixHeader.new_from_stream(@io)
            return if header.empty?

            entry = EntryStream.new(header, @io)
            size  = entry.size

            yield entry

            skip = (512 - (size % 512)) % 512

            if Archive::Tar::Minitar.seekable?(@io, :seek)
              # avoid reading...
              @io.seek(size - entry.bytes_read, IO::SEEK_CUR)
            else
              pending = size - entry.bytes_read
              while pending > 0
                bread = @io.read([pending, 4096].min).size
                raise UnexpectedEOF if @io.eof?
                pending -= bread
              end
            end
            @io.read(skip) # discard trailing zeros
            # make sure nobody can use #read, #getc or #rewind anymore
            entry.close
          end
        end

        def close
        end
      end
    end
  end
end
