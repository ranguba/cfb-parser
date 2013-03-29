# Copyright (C) 2013  Kouhei Sutou <kou@clear-code.com>
#
# This library is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library.  If not, see
# <http://www.gnu.org/licenses/>.

# [MS-CFB]: Compound File Binary File Format
# http://msdn.microsoft.com/en-us/library/dd942138.aspx

module CFB
  class Parser
    class Error < StandardError
    end

    class << self
      def parse(stream)
        new(stream).parse
      end
    end

    attr_reader :major_version
    attr_reader :minor_version
    attr_reader :sector_size
    attr_reader :mini_sector_size
    attr_reader :n_directory_sectors
    def initialize(stream)
      @stream = stream
      @stream.set_encoding("ASCII-8BIT", "ASCII-8BIT")
      @buffer = "".force_encoding("ASCII-8BIT")
    end

    def parse
      read_header_signature
      read_header_class_id
      read_version
      read_byte_order
      read_sector_shift
      read_mini_sector_shift
      read_reserved
      read_n_directory_sectors
    end

    private
    def read(n_bytes)
      @stream.read(n_bytes, @buffer)
    end

    HEADER_SIGNATURE = "\xD0\xCF\x11\xE0\xA1\xB1\x1A\xE1"
    def read_header_signature
      @header_signature = read(8).dup
      if @header_signature != HEADER_SIGNATURE
        raise Error, "invalid header signature: <#{@header_signature.inspect}>"
      end
    end

    HEADER_CLASS_ID = "\x00" * 16
    def read_header_class_id
      @class_id = read(16).dup
      if @class_id != HEADER_CLASS_ID
        raise Error, "invalid header class ID: <#{@class_id.inspect}>"
      end
    end

    def read_version
      minor_version_raw = read(2).dup
      major_version_raw = read(2).dup
      @minor_version = minor_version_raw.unpack("v")[0]
      @major_version = major_version_raw.unpack("v")[0]
      if @major_version != 0x003 and @major_version != 0x0004
        raise Error, "invalid major version: <#{major_version_raw.inspect}>"
      end
      # SHOULD: report warning?
      # if @minor_version != 0x003E
      #   raise Error, "invalid minor version: <#{minor_version_raw.inspect}>"
      # end
    end

    LITTLE_ENDIAN_BOM = "\xFE\xFF"
    def read_byte_order
      bom = read(2)
      if bom != LITTLE_ENDIAN_BOM
        raise Error, "invalid byte order: <#{bom.inspect}>"
      end
    end

    def read_sector_shift
      shift_raw = read(2)
      @sector_shift = shift_raw.unpack("v")[0]
      case @major_version
      when 0x0003
        if @sector_shift != 0x0009
          message = "invalid sector shift for major version 3: "
          message << "<#{shift_raw.inspect}>"
          raise Error, message
        end
      when 0x0004
        if @sector_shift != 0x000C
          message = "invalid sector shift for major version 4: "
          message << "<#{shift_raw.inspect}>"
          raise Error, message
        end
      end
      @sector_size = 2 ** @sector_shift
    end

    def read_mini_sector_shift
      shift_raw = read(2)
      @mini_sector_shift = shift_raw.unpack("v")[0]
      if @mini_sector_shift != 0x0006
        raise Error, "invalid mini sector shift: <#{shift_raw.inspect}>"
      end
      @mini_sector_size = 2 ** @mini_sector_shift
    end

    def read_reserved
      read(6)
    end

    def read_n_directory_sectors
      n_directory_sectors_raw = read(4)
      @n_directory_sectors = n_directory_sectors_raw.unpack("v")[0]
      if @major_version == 0x0003
        unless @n_directory_sectors.zero?
          message = "invalid number of directory sectors for major version 3: "
          message << "<#{n_directory_sectors_raw.inspect}>"
          raise Error, message
        end
      end
    end
  end
end
