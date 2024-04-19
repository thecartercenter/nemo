# frozen_string_literal: true

UUID_FORMAT = /<((?:grp|qing|os|on)[a-z0-9\-]+)>/

# Given a directory path DIR,
# save a list of every unique NEMO UUID discovered in the XML form submission files there.
#
# e.g. DIR="$HOME/instances" be rails create_uuid_list
task create_uuid_list: :environment do
  dir = ENV["DIR"]
  files = Dir.glob("#{dir}/**/*.xml")

  ids = {}
  last_count = 0
  files.each do |f|
    puts "Reading #{f}..."
    data = File.read(f)

    total = 0
    data.scan(UUID_FORMAT) do |matches|
      total += 1
      uuid = matches[0]
      ids[uuid] = true
    end

    puts "Found #{total} IDs (#{ids.count - last_count} new)."
    last_count = ids.count
  end

  puts "\n"
  puts ids.keys.sort.inspect
  puts "\n#{ids.count} unique IDs."
end
