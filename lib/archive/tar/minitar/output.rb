# coding: utf-8

require 'archive/tar/minitar/writer'

module Archive
  module Tar
    module Minitar
      # Wraps a Archive::Tar::Minitar::Writer with convenience methods and
      # wrapped stream management; Output only works with random access data
      # streams. See Output::new for details.
      class Output
        # With no associated block, +Output::open+ is a synonym for
        # +Output::new+. If the optional code block is given, it will be passed
        # the new _writer_ as an argument and the Output object will
        # automatically be closed when the block terminates. In this instance,
        # +Output::open+ returns the value of the block.
        def self.open(output)
          stream = new(output)
          return stream unless block_given?

          begin
            res = yield stream
          ensure
            stream.close
          end

          res
        end

        # Creates a new Output object. If +output+ is a stream object that
        # responds to #read), then it will simply be wrapped. Otherwise, one will
        # be created and opened using Kernel#open. When Output#close is called,
        # the stream object wrapped will be closed.
        def initialize(output)
          if output.respond_to?(:write)
            @io = output
          else
            @io = ::File.open(output, "wb")
          end
          @tarwriter = Archive::Tar::Minitar::Writer.new(@io)
        end

        # Returns the Writer object for direct access.
        def tar
          @tarwriter
        end

        # Closes the Writer object and the wrapped data stream.
        def close
          @tarwriter.close
          @io.close
        end
      end
    end
  end
end
