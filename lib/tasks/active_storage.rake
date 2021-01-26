# frozen_string_literal: true

namespace :active_storage do
  # Expectation: ActiveStorage syntax is NOT yet migrated
  # (e.g. has_attached_file, NOT has_one_attached).
  #
  # By default, Paperclip looks like this:
  # public/system/users/avatars/000/000/004/original/the-mystery-of-life.png
  #
  # And ActiveStorage looks like this locally (or all in root directory for cloud storage):
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

# This can't be a constant because rake needs environment first.
def nemo_attachments
  [
    [Operation, "attachment"],
    [SavedUpload, "file"],
    [SavedTabularUpload, "file"],
    [Question, "media_prompt"],
    [Media::Audio, "item"],
    [Media::Image, "item"],
    [Media::Video, "item"],
    [Response, "odk_xml"]
  ].freeze
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

def copy_all_s3
  puts "Using CLOUD storage."

  nemo_attachments.each do |pair|
    relation, title = pair
    relation = relation.where.not("#{title}_file_size".to_sym => nil)

    puts "Copying #{relation.count} #{relation.name} #{title.pluralize}..."
    relation.order(id: :desc).find_each do |record|
      copy_s3_item(record, title)
    end
  end
end

# Download a Paperclip item from S3 and re-attach it using ActiveStorage.
# Paperclip path defaults to `:class/:attachment/:id_partition/:style/:filename`.
def copy_s3_item(record, title)
  filename = record.send("#{title}_file_name")
  model_path = record.class.name.pluralize.downcase.gsub("::", "/")
  record_path = "#{model_path}/#{title.pluralize}/#{id_partition(record.id)}/original/#{CGI.escape(filename)}"
  url = "https://#{ENV['NEMO_AWS_BUCKET']}.s3.#{ENV['NEMO_AWS_REGION']}.amazonaws.com/#{record_path}"

  # Hack to avoid double-saving files when testing this multiple times in a row
  # (no fast way to determine if an attachment is stored in ActiveStorage vs. Paperclip location).
  if ENV["SKIP_MINUTES_AGO"].present? &&
      record.send(title).attachment.created_at > ENV["SKIP_MINUTES_AGO"].to_f.minutes.ago
    puts "Skipping existing #{filename}"
  else
    puts "Copying #{filename}\n  at #{url}"
    record.send(title).attach(io: URI.open(url), filename: filename,
                              content_type: record.send("#{title}_content_type"))
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
