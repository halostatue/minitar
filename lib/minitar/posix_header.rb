# frozen_string_literal: true

class Minitar
  # Implements the POSIX tar header as a Ruby class. The structure of
  # the POSIX tar header is:
  #
  #   struct tarfile_entry_posix
  #   {                      //                               pack   unpack
  #      char name[100];     // ASCII (+ Z unless filled)     a100   Z100
  #      char mode[8];       // 0 padded, octal, null         a8     A8
  #      char uid[8];        // 0 padded, octal, null         a8     A8
  #      char gid[8];        // 0 padded, octal, null         a8     A8
  #      char size[12];      // 0 padded, octal, null         a12    A12
  #      char mtime[12];     // 0 padded, octal, null         a12    A12
  #      char checksum[8];   // 0 padded, octal, null, space  a8     A8
  #      char typeflag[1];   // see below                     a      a
  #      char linkname[100]; // ASCII + (Z unless filled)     a100   Z100
  #      char magic[6];      // "ustar\0"                     a6     A6
  #      char version[2];    // "00"                          a2     A2
  #      char uname[32];     // ASCIIZ                        a32    Z32
  #      char gname[32];     // ASCIIZ                        a32    Z32
  #      char devmajor[8];   // 0 padded, octal, null         a8     A8
  #      char devminor[8];   // 0 padded, octal, null         a8     A8
  #      char prefix[155];   // ASCII (+ Z unless filled)     a155   Z155
  #   };
  #
  # The #typeflag is one of several known values. POSIX indicates that "A POSIX-compliant
  # implementation must treat any unrecognized typeflag value as a regular file."
  class PosixHeader
    BLOCK_SIZE = 512
    MAGIC_BYTES = "ustar"

    GNU_EXT_LONG_LINK = "././@LongLink"

    # Fields that must be set in a POSIX tar(1) header.
    REQUIRED_FIELDS = [:name, :size, :prefix, :mode].freeze
    # Fields that may be set in a POSIX tar(1) header.
    OPTIONAL_FIELDS = [
      :uid, :gid, :mtime, :checksum, :typeflag, :linkname, :magic, :version, :uname,
      :gname, :devmajor, :devminor
    ].freeze

    # All fields available in a POSIX tar(1) header.
    FIELDS = (REQUIRED_FIELDS + OPTIONAL_FIELDS).freeze

    FIELDS.each do |f|
      attr_reader f.to_sym
    end

    ##
    def name=(value)
      valid_name!(value)
      @name = value
    end

    attr_writer :size

    # The pack format passed to Array#pack for encoding a header.
    HEADER_PACK_FORMAT = "a100a8a8a8a12a12a7aaa100a6a2a32a32a8a8a155"
    # The unpack format passed to String#unpack for decoding a header.
    HEADER_UNPACK_FORMAT = "Z100A8A8A8a12A12A8aZ100A6A2Z32Z32A8A8Z155"

    class << self
      # Creates a new PosixHeader from a data stream.
      def from_stream(stream) = from_data(stream.read(BLOCK_SIZE))

      # Creates a new PosixHeader from a BLOCK_SIZE-byte data buffer.
      def from_data(data)
        fields = data.unpack(HEADER_UNPACK_FORMAT)
        name = fields.shift
        mode = fields.shift.oct
        uid = fields.shift.oct
        gid = fields.shift.oct
        size = parse_numeric_field(fields.shift)
        mtime = fields.shift.oct
        checksum = fields.shift.oct
        typeflag = fields.shift
        linkname = fields.shift
        magic = fields.shift
        version = fields.shift.oct
        uname = fields.shift
        gname = fields.shift
        devmajor = fields.shift.oct
        devminor = fields.shift.oct
        prefix = fields.shift

        empty = !data.each_byte.any?(&:nonzero?)

        new(
          name: name,
          mode: mode,
          uid: uid,
          gid: gid,
          size: size,
          mtime: mtime,
          checksum: checksum,
          typeflag: typeflag,
          magic: magic,
          version: version,
          uname: uname,
          gname: gname,
          devmajor: devmajor,
          devminor: devminor,
          prefix: prefix,
          empty: empty,
          linkname: linkname
        )
      end

      private

      def parse_numeric_field(string)
        return string.oct if /\A[0-7 \0]*\z/.match?(string) # \0 appears as a padding
        return parse_base256(string) if string.bytes.first == 0x80 || string.bytes.first == 0xff
        raise ArgumentError, "#{string.inspect} is not a valid numeric field"
      end

      def parse_base256(string)
        # https://www.gnu.org/software/tar/manual/html_node/Extensions.html
        bytes = string.bytes
        case bytes.first
        when 0x80 # Positive number: *non-leading* bytes, number in big-endian order
          bytes[1..].inject(0) { |r, byte| (r << 8) | byte }
        when 0xff # Negative number: *all* bytes, two's complement in big-endian order
          result = bytes.inject(0) { |r, byte| (r << 8) | byte }
          bit_length = bytes.size * 8
          result - (1 << bit_length)
        else
          raise ArgumentError, "Invalid binary field format"
        end
      end
    end

    # Creates a new PosixHeader. A PosixHeader cannot be created unless +name+, +size+,
    # +prefix+, and +mode+ are provided.
    def initialize(v)
      REQUIRED_FIELDS.each do |f|
        raise ArgumentError, "Field #{f} is required." unless v.key?(f)
      end

      v[:mtime] = v[:mtime].to_i
      v[:checksum] ||= ""
      v[:typeflag] ||= "0"
      v[:magic] ||= MAGIC_BYTES
      v[:version] ||= "00"

      FIELDS.each do |f|
        instance_variable_set(:"@#{f}", v[f])
      end

      @empty = v[:empty]

      valid_name!(v[:name]) unless v[:empty]
    end

    # Indicates if the header was an empty header.
    def empty? = @empty

    # Indicates if the header has a valid magic value.
    def valid? = empty? || @magic == MAGIC_BYTES

    # Returns +true+ if the header is a long name special header which indicates
    # that the next block of data is the filename.
    def long_name? = typeflag == "L" && name == GNU_EXT_LONG_LINK

    # Returns +true+ if the header is a PAX extended header which contains
    # metadata for the next file entry.
    def pax_header? = typeflag == "x"

    # Sets the +name+ to the +value+ provided and clears +prefix+.
    #
    # Used by Minitar::Reader#each_entry to set the long name when processing GNU long
    # filename extensions.
    #
    # The +value+ must be the complete name, including leading directory components.
    def long_name=(value)
      valid_name!(value)

      @prefix = ""
      @name = value
    end

    # A string representation of the header.
    def to_s
      update_checksum
      header(@checksum)
    end
    alias_method :to_str, :to_s

    # TODO: In Minitar 2, PosixHeader#to_str will be removed.

    # Update the checksum field.
    def update_checksum
      hh = header(" " * 8)
      @checksum = oct(calculate_checksum(hh), 6)
    end

    private

    def valid_name!(value)
      return if value.is_a?(String) && !value.empty?
      raise ArgumentError, "Field name must be a non-empty string"
    end

    def oct(num, len)
      if num.nil?
        "\0" * (len + 1)
      else
        "%0#{len}o" % num
      end
    end

    def calculate_checksum(hdr)
      hdr.unpack("C*").inject(:+)
    end

    def header(chksum)
      arr = [name, oct(mode, 7), oct(uid, 7), oct(gid, 7), oct(size, 11),
        oct(mtime, 11), chksum, " ", typeflag, linkname, magic, version,
        uname, gname, oct(devmajor, 7), oct(devminor, 7), prefix]
      str = arr.pack(HEADER_PACK_FORMAT)
      str + "\0" * ((BLOCK_SIZE - str.bytesize) % BLOCK_SIZE)
    end

    ##
    # :attr_accessor: name
    # The name of the file. Required.
    #
    # By default, limited to 100 bytes, but may be up to BLOCK_SIZE bytes if using the
    # GNU long name tar extension.

    ##
    # :attr_accessor: size
    # The size of the file. Required.

    ##
    # :attr_reader: prefix
    # The prefix of the file; the path before #name. Limited to 155 bytes.
    # Required.

    ##
    # :attr_reader: mode
    # The Unix file mode of the file. Stored as an octal integer. Required.

    ##
    # :attr_reader: uid
    # The Unix owner user ID of the file. Stored as an octal integer.

    ##
    # :attr_reader: uname
    # The user name of the Unix owner of the file.

    ##
    # :attr_reader: gid
    # The Unix owner group ID of the file. Stored as an octal integer.

    ##
    # :attr_reader: gname
    # The group name of the Unix owner of the file.

    ##
    # :attr_reader: mtime
    # The modification time of the file in epoch seconds. Stored as an
    # octal integer.

    ##
    # :attr_reader: checksum
    # The checksum of the file. Stored as an octal integer. Calculated
    # before encoding the header as a string.

    ##
    # :attr_reader: typeflag
    # The type of record in the file.
    #
    # +0+::  Regular file. NULL should be treated as a synonym, for compatibility
    #        purposes.
    # +1+::  Hard link.
    # +2+::  Symbolic link.
    # +3+::  Character device node.
    # +4+::  Block device node.
    # +5+::  Directory.
    # +6+::  FIFO node.
    # +7+::  Reserved.
    # +L+::  GNU extension for long filenames when #name is <tt>././@LongLink</tt>.

    ##
    # :attr_reader: linkname
    # The target of the symbolic link.

    ##
    # :attr_reader: magic
    # Always "ustar\0".

    ##
    # :attr_reader: version
    # Always "00"

    ##
    # :attr_reader: devmajor
    # The major device ID. Not currently used.

    ##
    # :attr_reader: devminor
    # The minor device ID. Not currently used.
  end
end
