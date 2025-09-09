# frozen_string_literal: true

# Implements the PAX Extended Header as a Ruby class. The header consists of following
# format:
#
# ```
# <decimal-length><space><ascii-keyword>=<value><newline>
# ```
#
# Where:
#
# - `decimal-length`: the total number of bytes for the PaxHeader record using ASCII
#   decimal values; this includes the terminal newline (0x10).
# - `space` is a single literal ASCII space (0x20).
# - `ascii-keyword` is a PAX Extended Header keyword, which may be any ASCII character
#   except newline (0x10) or equal sign (0x3D).
# - `=` is the literal ASCII equal sign (0x3D).
# - `value` is any series of bytes except newline (0x10).
# - `newline` is the literal ASCII newline (0x10).
#
# There are several keywords defined in the POSIX standard; some of them are supported in
# this class, but may not be supported by Minitar as a whole.
#
# Primary support for PAX extended headers is for extracting size information for large
# file support. Other features may be added in the future.
class Minitar::PaxHeader
  BLOCK_SIZE = 512

  attr_reader :attributes

  class << self
    # Creates a new PaxHeader from a data stream and posix header. Reads the PAX content
    # based on the size specified in the posix header.
    def from_stream(stream, posix_header)
      raise ArgumentError, "Header must be a PAX header" unless posix_header.pax_header?

      pax_block = (posix_header.size / BLOCK_SIZE.to_f).ceil * BLOCK_SIZE
      pax_content = stream.read(pax_block)

      raise Minitar::InvalidTarStream if pax_content.nil? || pax_content.bytesize < posix_header.size

      actual_content = pax_content[0, posix_header.size]

      from_data(actual_content)
    end

    # Creates a new PaxHeader from PAX content data.
    def from_data(content) = new(parse_content(content))

    private

    def parse_content(content)
      attributes = {}
      offset = 0

      while offset < content.bytesize
        space_pos = content.index(" ", offset)
        break unless space_pos

        length_str = content[offset, space_pos - offset]

        unless length_str.match?(/\A\d+\z/)
          raise ArgumentError, "Invalid length format in PAX header: '#{length_str}'"
        end

        length = length_str.to_i
        if offset + length > content.bytesize
          raise ArgumentError, "Length beyond PAX header: '#{content[offset..]}'"
        end
        record = content[offset, length]

        keyword_value = record[(space_pos - offset + 1)..-2]
        if keyword_value.include?("=")
          keyword, value = keyword_value.split("=", 2)
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
  def size = @attributes["size"]&.to_i

  # The path value from PAX attributes
  def path = @attributes["path"]

  # The mtime value from PAX attributes
  def mtime = @attributes["mtime"]&.to_f

  # Returns a string representation of the PAX header content.
  def to_s
    @attributes.map do |keyword, value|
      keyword_value = " #{keyword}=#{value}\n"
      record = keyword_value
      begin
        length = record.bytesize
        length_str = length.to_s
        record = "#{length_str}#{keyword_value}"
      end while record.size != length # standard:disable Lint/Loop
      record
    end.join
  end
end
