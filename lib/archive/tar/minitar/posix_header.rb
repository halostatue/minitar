# coding: utf-8

module Archive
  module Tar
    module Minitar
      # Implements the POSIX tar header as a Ruby class. The structure of
      # the POSIX tar header is:
      #
      #   struct tarfile_entry_posix
      #   {                      //                               pack/unpack
      #      char name[100];     // ASCII (+ Z unless filled)     a100/Z100
      #      char mode[8];       // 0 padded, octal, null         a8  /A8
      #      char uid[8];        // ditto                         a8  /A8
      #      char gid[8];        // ditto                         a8  /A8
      #      char size[12];      // 0 padded, octal, null         a12 /A12
      #      char mtime[12];     // 0 padded, octal, null         a12 /A12
      #      char checksum[8];   // 0 padded, octal, null, space  a8  /A8
      #      char typeflag[1];   // see below                     a   /a
      #      char linkname[100]; // ASCII + (Z unless filled)     a100/Z100
      #      char magic[6];      // "ustar\0"                     a6  /A6
      #      char version[2];    // "00"                          a2  /A2
      #      char uname[32];     // ASCIIZ                        a32 /Z32
      #      char gname[32];     // ASCIIZ                        a32 /Z32
      #      char devmajor[8];   // 0 padded, octal, null         a8  /A8
      #      char devminor[8];   // 0 padded, octal, null         a8  /A8
      #      char prefix[155];   // ASCII (+ Z unless filled)     a155/Z155
      #   };
      #
      # The +typeflag+ may be one of the following known values:
      #
      # <tt>"0"</tt>::  Regular file. NULL should be treated as a synonym, for
      #                 compatibility purposes.
      # <tt>"1"</tt>::  Hard link.
      # <tt>"2"</tt>::  Symbolic link.
      # <tt>"3"</tt>::  Character device node.
      # <tt>"4"</tt>::  Block device node.
      # <tt>"5"</tt>::  Directory.
      # <tt>"6"</tt>::  FIFO node.
      # <tt>"7"</tt>::  Reserved.
      #
      # POSIX indicates that "A POSIX-compliant implementation must treat any
      # unrecognized typeflag value as a regular file."
      class PosixHeader
        REQUIRED_FIELDS = [ :name, :size, :prefix, :mode ].freeze
        OPTIONAL_FIELDS = [
          :uid, :gid, :mtime, :checksum, :typeflag, :linkname, :magic, :version,
          :uname, :gname, :devmajor, :devminor
        ].freeze

        FIELDS = (REQUIRED_FIELDS + OPTIONAL_FIELDS).freeze

        FIELDS.each { |f| attr_reader f.to_sym }

        HEADER_PACK_FORMAT    = "a100a8a8a8a12a12a7aaa100a6a2a32a32a8a8a155"
        HEADER_UNPACK_FORMAT  = "Z100A8A8A8A12A12A8aZ100A6A2Z32Z32A8A8Z155"

        class << self
          # Creates a new PosixHeader from a data stream.
          def new_from_stream(stream)
            data = stream.read(512)
            fields    = data.unpack(HEADER_UNPACK_FORMAT)
            name      = fields.shift
            mode      = fields.shift.oct
            uid       = fields.shift.oct
            gid       = fields.shift.oct
            size      = fields.shift.oct
            mtime     = fields.shift.oct
            checksum  = fields.shift.oct
            typeflag  = fields.shift
            linkname  = fields.shift
            magic     = fields.shift
            version   = fields.shift.oct
            uname     = fields.shift
            gname     = fields.shift
            devmajor  = fields.shift.oct
            devminor  = fields.shift.oct
            prefix    = fields.shift

            empty = (data == "\0" * 512)

            new(:name => name, :mode => mode, :uid => uid, :gid => gid,
                :size => size, :mtime => mtime, :checksum => checksum,
                :typeflag => typeflag, :magic => magic, :version => version,
                :uname => uname, :gname => gname, :devmajor => devmajor,
                :devminor => devminor, :prefix => prefix, :empty => empty,
                :linkname => linkname)
          end
        end

        # Creates a new PosixHeader. A PosixHeader cannot be created unless
        # +name+, +size+, +prefix+, and +mode+ are provided.
        def initialize(v)
          REQUIRED_FIELDS.each do |f|
            raise ArgumentError, "Field #{f} is required." unless v.has_key?(f)
          end

          v[:mtime]    = v[:mtime].to_i
          v[:checksum] ||= ""
          v[:typeflag] ||= "0"
          v[:magic]    ||= "ustar"
          v[:version]  ||= "00"

          FIELDS.each { |f| instance_variable_set("@#{f}", v[f]) }

          @empty = v[:empty]
        end

        def empty?
          @empty
        end

        def to_s
          update_checksum
          header(@checksum)
        end
        alias_method :to_str, :to_s

        # Update the checksum field.
        def update_checksum
          hh = header(" " * 8)
          @checksum = oct(calculate_checksum(hh), 6)
        end

        private
        def oct(num, len)
          if num.nil?
            "\0" * (len + 1)
          else
            "%0#{len}o" % num
          end
        end

        def calculate_checksum(hdr)
          hdr.unpack("C*").inject { |aa, bb| aa + bb }
        end

        def header(chksum)
          arr = [name, oct(mode, 7), oct(uid, 7), oct(gid, 7), oct(size, 11),
                 oct(mtime, 11), chksum, " ", typeflag, linkname, magic, version,
                 uname, gname, oct(devmajor, 7), oct(devminor, 7), prefix]
          str = arr.pack(HEADER_PACK_FORMAT)
          str + "\0" * ((512 - str.size) % 512)
        end
      end
    end
  end
end
