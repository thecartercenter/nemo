# frozen_string_literal: true

KEY_ID_FORMAT = /<((?:grp|qing)[a-z0-9\-]+)>/
VALUE_ID_FORMAT = />((?:os|on)[a-z0-9\-]+)</

# Given a directory path DIR,
# save a list of every unique NEMO UUID discovered in the XML form submission files there.
#
# e.g. DIR="$HOME/instances" be rails create_uuid_list
task create_uuid_list: :environment do
  dir = ENV.fetch("DIR", nil)
  files = Dir.glob("#{dir}/**/*.xml")

  ids = {}
  last_count = 0
  files.each do |f|
    puts "Reading #{f}..."
    data = File.read(f)

    total = 0
    data.scan(KEY_ID_FORMAT) do |matches|
      total += 1
      uuid = matches[0]
      ids[uuid] = true
    end

    data.scan(VALUE_ID_FORMAT) do |matches|
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

# require './list.rb'
#
# UUID_FORMAT = /(grp|qing|os|on)(.+)/
#
# table = {}
# errors = []
# LIST.each do |id|
#   puts id
#   id.scan(UUID_FORMAT) do |matches|
#     type = matches[0]
#     uuid = matches[1]
#
#     result = nil
#     case type
#     when "grp"
#       obj = FormItem.find_by(id: uuid)
#       result = obj ? obj.group_name || "[Blank]" : "[Nonexistent ID: #{id}]"
#       errors << id unless obj&.group_name.present?
#     when "qing"
#       obj = FormItem.find_by(id: uuid)
#       result = obj ? obj.code || "[Blank]" : "[Nonexistent ID: #{id}]"
#       errors << id unless obj&.code.present?
#     when "os"
#       obj = OptionSet.find_by(id: uuid)
#       result = obj ? obj.name || "[Blank]" : "[Nonexistent ID: #{id}]"
#       errors << id unless obj&.name.present?
#     when "on"
#       obj = OptionNode.find_by(id: uuid)
#       result = obj ? obj.name || "[Blank]" : "[Nonexistent ID: #{id}]"
#       errors << id unless obj&.name.present?
#     else
#       result = "[Unknown type]"
#     end
#     table[id] = result
#   end
# end
# puts "\nTable:"
# puts table.to_json
# puts "\nErrors:"
# puts errors.inspect

1
