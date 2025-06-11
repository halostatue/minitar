# frozen_string_literal: true

class Minitar
  # Implements the PAX Extended Header as a Ruby class. The header consists of following strings:
  #
  #    "#{length} #{keyword}=#{value}\n"
  #
  # There are several keywords defined in the POSIX standard and some of it are supported in this class.
  # This class provides minimal functionality to extract size information for large file support.
  class PaxHeader
    BLOCK_SIZE = 512

    attr_reader :attributes

    class << self
      # Creates a new PaxHeader from a data stream and posix header.
      # Reads the PAX content based on the size specified in the posix header.
      def from_stream(stream, posix_header)
        raise ArgumentError, "Header must be a PAX header" unless posix_header.pax_header?

        pax_block = (posix_header.size / BLOCK_SIZE.to_f).ceil * BLOCK_SIZE
        pax_content = stream.read(pax_block)

        raise Minitar::InvalidTarStream if pax_content.nil? || pax_content.bytesize < posix_header.size

        actual_content = pax_content[0, posix_header.size]

        from_data(actual_content)
      end

      # Creates a new PaxHeader from PAX content data.
      def from_data(content)
        new(parse_content(content))
      end

      private

      def parse_content(content)
        attributes = {}
        offset = 0
        while offset < content.bytesize
          space_pos = content.index(' ', offset)
          break unless space_pos

          length_str = content[offset, space_pos - offset]
          unless length_str.match?(/\A\d+\z/)
            raise ArgumentError, "Invalid length format in PAX header: '#{length_str}'"
          end

          length = length_str.to_i
          if offset + length > content.bytesize
            raise ArgumentError, "Length beyond PAX header: '#{content[offset..-1]}'"
          end
          record = content[offset, length]

          keyword_value = record[(space_pos - offset + 1)..-2]
          if keyword_value.include?('=')
            keyword, value = keyword_value.split('=', 2)
            attributes[keyword] = value
          end

          offset += length
        end
        attributes
      end
    end

    # Creates a new PaxHeader from attributes hash.
    def initialize(attributes = {})
      @attributes = attributes.transform_keys(&:to_s)
    end

    # The size value from PAX attributes
    def size
      @attributes['size']&.to_i
    end

    # The path value from PAX attributes
    def path
      @attributes['path']
    end

    # The mtime value from PAX attributes
    def mtime
      @attributes['mtime']&.to_f
    end

    # Returns a string representation of the PAX header content.
    def to_s
      @attributes.map do |keyword, value|
        keyword_value = " #{keyword}=#{value}\n"
        record = keyword_value
        begin
          length = record.bytesize
          length_str = length.to_s
          record = "#{length_str}#{keyword_value}"
        end while record.size != length
        record
      end.join
    end

  end
end
