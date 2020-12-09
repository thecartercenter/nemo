# frozen_string_literal: true

namespace :active_storage do
  # Expectation: ActiveStorage is used (e.g. has_one_attached, NOT has_attached_file).
  # From https://github.com/thoughtbot/paperclip/blob/master/MIGRATING.md
  desc "Copies attachments from Paperclip => ActiveStorage directory (on AWS S3)"
  task copy_s3: :environment do
    # TODO: All other models too
    copy_all_s3(User.where.not(image_file_name: nil))
  end
end

def copy_all_s3(relation)
  puts "Copying #{relation.count} #{relation.name} attachments..."
  relation.order(id: :desc).find_each do |record|
    copy_s3(record)
  end
end

def copy_s3(record)
  filename = record.image_file_name
  model = record.class.name.pluralize.downcase
  # Paperclip defaults to `:class/:attachment/:id_partition/:style/:filename`.
  record_path = "#{model}/images/#{id_partition(record.id)}/original/#{CGI.escape(filename)}"
  image_url = "https://#{ENV['S3_BUCKET_NAME']}.s3.us-east-1.amazonaws.com/#{record_path}"
  # Hack to avoid double-saving files when running this multiple times in a row.
  # TODO: Find a better way to determine if an attachment is AciveStorage vs. Paperclip.
  if record.image.attachment.created_at > 1.hour.ago
    puts "Skipping existing #{filename}"
  else
    puts "Copying #{filename}\n  at #{image_url}"
    record.image.attach(io: open(image_url),
                        filename: filename,
                        content_type: record.image_content_type)
  end
end

# From Paperclip source:
# https://github.com/thoughtbot/paperclip/blob/v4.2.4/lib/paperclip/interpolations.rb#L170
#
# Returns the id of the instance in a split path form. e.g. returns
# 000/001/234 for an id of 1234.
#
# rubocop:disable all
def id_partition(id)
  case id
  when Integer
    ("%09d" % id).scan(/\d{3}/).join("/")
  when String
    ('%9.9s' % id).tr(" ", "0").scan(/.{3}/).join("/")
  else
    nil
  end
end
# rubocop:enable
