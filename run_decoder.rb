require 'decode_mbdb'

data_b = File.read("Manifest.mbdb")
dec_b = ITunesArchive::BDecoder.new(data_b)
items = dec_b.decode_all

data_x = File.read("Manifest.mbdx")
dec_x = ITunesArchive::XDecoder.new(data_x)
shas = dec_x.decode_all

puts "Found #{items.count} items and #{shas.count} shas"

itemmap = items.inject({}) {|h,i| h[i.offset] = i; h}

shas.each do |sha|
  item = itemmap[sha.offset]
  item.sha = sha
  sha.item = item
end

items.each do |item|
  sha = item.sha
  if File.exist? sha.sha
    FileUtils.mkdir_p File.dirname(item.filename)
    if File.exist? item.filename
      puts "Skipping: #{item.sha.sha} => #{item.filename}"
    else
      puts "Linking: #{item.sha.sha} => #{item.filename}"
      FileUtils.ln sha.sha, item.filename
    end
  end
end
