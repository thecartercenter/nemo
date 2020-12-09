# frozen_string_literal: true

namespace :active_storage do
  # Expectation: ActiveStorage syntax is NOT yet migrated
  # (e.g. has_attached_file, NOT has_one_attached).
  #
  # By default, Paperclip looks like this:
  # public/system/users/avatars/000/000/004/original/the-mystery-of-life.png
  #
  # And ActiveStorage looks like this:
  # storage/xM/RX/xMRXuT6nqpoiConJFQJFt6c9
  #
  # From https://github.com/thoughtbot/paperclip/blob/master/MIGRATING.md
  desc "Copies attachments from Paperclip => ActiveStorage directory (locally or on AWS S3)"
  task copy_from_paperclip: :environment do
    if Rails.configuration.active_storage.service == :local
      copy_all_local
    else
      copy_all_s3
    end
  end
end

def copy_all_local
  puts "Using LOCAL storage."

  ActiveStorage::Attachment.order(id: :desc).find_each do |attachment|
    name = attachment.name
    source = attachment.record.send(name).path
    dest_dir = File.join("storage", attachment.blob.key.first(2), attachment.blob.key.first(4).last(2))
    dest = File.join(dest_dir, attachment.blob.key)

    puts "Copying #{source}\n  to #{dest}"
    FileUtils.mkdir_p(dest_dir)
    FileUtils.cp(source, dest)
  end
end

# TODO: Cloud migration was originally written with expectation that ActiveStorage syntax is already migrated.
#   It's now the opposite, so this will definitely not work.
def copy_all_s3
  puts "Using CLOUD storage."

  # TODO: Grab all NEMO relations.
  relations = [
    # e.g. User.where.not(image_file_name: nil)
    #
    # Response odk_xml
    # SavedUpload file
    # Operation attachment
    # ::Media::Object (image, audio, video) item
    # Mediable (ODK generic) media_prompt
  ]

  relations.each do |relation|
    puts "Copying #{relation.count} #{relation.name} attachments..."
    relation.order(id: :desc).find_each do |record|
      copy_s3_item(record)
    end
  end
end

def copy_s3_item(record)
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
