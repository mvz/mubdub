# 
# See also:
# http://www.employees.org/~mstenber/iphonebackupdb.py
#

module ITunesArchive
  class Item
    attr_accessor :vendor, :filename, :bonus, :garbage, :extra, :offset, :sha
  end

  class Sha
    attr_accessor :sha, :offset, :item
  end

  class Decoder
    attr_reader :offset
    def initialize(data)
      @data = data
      @offset = 0
    end

    def get_int
      read(4).unpack("N").first
    end

    def get_short
      read(2).unpack("n").first
    end

    def get_byte
      read(1).unpack("C").first
    end

    def read(num)
      @data[@offset, num].tap { @offset += num }
    end
  end

  class BDecoder < Decoder
    def decode_all
      get_header
      items = []
      while @offset < @data.length do
        items << get_item
      end
      items
    end

    def get_header
      [read(4), get_short]
    end

    def get_item
      Item.new.tap { |i|
        i.offset = self.offset - 6
        i.vendor = get_string
        i.filename = get_string
        i.bonus = (1..3).map { get_string }
        i.garbage = read(39)
        cnt = get_byte
        i.extra = (1..cnt).map { [get_string, get_string] }
      }
    end

    def get_string
      length = get_short
      length == 0xffff ? '' : read(length)
    end
  end

  class XDecoder < Decoder
    def get_header
      [read(4), get_short, get_short, get_short]
    end

    def get_sha
      Sha.new.tap { |s|
        s.sha = read(20).unpack("H*").first
        s.offset = get_int
        get_short
      }
    end

    def decode_all
      get_header
      shas = []
      while @offset < @data.length do
        shas << get_sha
      end
      shas
    end
  end
end
