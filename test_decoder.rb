require 'iba'
require 'test/unit'
require "decode_mbdb.rb"

class Test::Unit::TestCase
  include Iba::BlockAssertion
end

class TestDecoder < Test::Unit::TestCase
  def test_read
    dec = ITunesArchive::Decoder.new("123456789")
    r = dec.read 5
    assert { r == "12345" }
    assert { dec.offset == 5 }
  end

  def test_get_short
    dec = ITunesArchive::Decoder.new("\x01\x06")
    s = dec.get_short
    assert { s == 0x0106 }
    assert { dec.offset == 2 }
  end

  def test_get_int
    dec = ITunesArchive::Decoder.new("\x01\x06\x31\x98")
    s = dec.get_int
    assert { s == 0x01063198 }
    assert { dec.offset == 4 }
  end
end

class TestBDecoder < Test::Unit::TestCase
  def test_get_string
    dec = ITunesArchive::BDecoder.new("\x00\x06Hello!GARBAGE")
    s = dec.get_string
    assert { s == "Hello!" }
  end

  def test_get_string_empty
    dec = ITunesArchive::BDecoder.new("\xff\xffGARBAGE")
    s = dec.get_string
    assert { s == "" }
  end

  def test_get_header
    dec = ITunesArchive::BDecoder.new("mbdb\x05\x00")
    header = dec.get_header
    assert { header == ["mbdb", 0x0500] }
  end

  def test_get_item_simple
    data = [
      "\x00\x06Vendor",     # vendor
      "\x00\x08Filename",   # filename
      "\xff\xff" * 3,       # 3 times bonus
      "GarbageGarbageGarbageGarbageGarbageGarb", # 39 bytes 'garbage'
      "\x00"                # Count 0 extra pairs
    ].join
    dec = ITunesArchive::BDecoder.new data
    item = dec.get_item
    assert { dec.offset == data.length }
    assert { item.vendor == "Vendor" }
    assert { item.filename == "Filename" }
  end

  def test_get_item_complex
    data = [
      "\x00\x06Vendor",     # vendor
      "\x00\x08Filename",   # filename
      "\x00\x06bonus1",     # bonus 1
      "\x00\x06bonus2",     # bonus 2
      "\x00\x06bonus3",     # bonus 3
      "GarbageGarbageGarbageGarbageGarbageGarb", # 39 bytes 'garbage'
      "\x03",                               # Count 3 extra pairs
      "\x00\x05key 1", "\x00\x07value 1",   # Pair 1
      "\x00\x05key 2", "\x00\x07value 2",   # Pair 1
      "\x00\x05key 3", "\x00\x07value 3"    # Pair 1
    ].join
    dec = ITunesArchive::BDecoder.new data
    item = dec.get_item
    assert { dec.offset == data.length }
    assert { item.vendor == "Vendor" }
    assert { item.filename == "Filename" }
    assert { item.bonus == ["bonus1", "bonus2", "bonus3"] }
    assert { item.garbage == "GarbageGarbageGarbageGarbageGarbageGarb" }
    assert { item.extra == [
      ["key 1", "value 1"],
      ["key 2", "value 2"],
      ["key 3", "value 3"]] }
  end

  def test_decode_all
    data = [
      "mbdb\x05\x00",       # header
      "\x00\x06Vendor",     # vendor
      "\x00\x08Filename",   # filename
      "\xff\xff" * 3,       # 3 times bonus
      "GarbageGarbageGarbageGarbageGarbageGarb", # 39 bytes 'garbage'
      "\x00",               # Count 0 extra pairs
      "\x00\x06Vendor",     # vendor
      "\x00\x08Filename",   # filename
      "\x00\x06bonus1",     # bonus 1
      "\x00\x06bonus2",     # bonus 2
      "\x00\x06bonus3",     # bonus 3
      "GarbageGarbageGarbageGarbageGarbageGarb", # 39 bytes 'garbage'
      "\x03",                               # Count 3 extra pairs
      "\x00\x05key 1", "\x00\x07value 1",   # Pair 1
      "\x00\x05key 2", "\x00\x07value 2",   # Pair 1
      "\x00\x05key 3", "\x00\x07value 3"    # Pair 1
    ].join
    dec = ITunesArchive::BDecoder.new data
    items = dec.decode_all
    assert { items.length == 2 }
    assert { items[0].offset == 0 }
    assert { items[1].offset == 64 }
  end
end

class TestXDecoder < Test::Unit::TestCase
  def test_get_header
    dec = ITunesArchive::XDecoder.new("mbdx\x02\x00\x00\x00\x08\x01DataData")
    h = dec.get_header
    assert { h == ["mbdx", 0x0200, 0x0000, 0x0801] }
    assert { dec.offset == 10 }
  end

  def test_get_sha
    dec = ITunesArchive::XDecoder.new("12345678901234567890\x01\x02\x03\x04\xab\xcd")
    s = dec.get_sha
    assert { dec.offset == 26 }
    assert { s.sha == "3132333435363738393031323334353637383930" }
    assert { s.offset == 0x01020304 }
  end

  def test_decode_all
    data = [
      "mbdx\x02\x00\x00\x00\x08\x01",                   # header
      "12345678901234567890\x01\x02\x03\x04\xde\xad",   # fist sha
      "abcdefghijklmnopqrst\x00\x0f\x61\x6b\xbe\xef"    # second sha
    ].join
    dec = ITunesArchive::XDecoder.new(data)
    shas = dec.decode_all
    assert { shas.length == 2 }
  end
end
