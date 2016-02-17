class Media::Object < ActiveRecord::Base
  belongs_to :answer

  has_attached_file :item
  validates_attachment_presence :item

  delegate :url, to: :item
  delegate :mission, to: :answer

  def download_url
    dl_url = url
    separator = (dl_url =~ /\?/) ? "&" : "?"
    "#{dl_url}#{separator}dl=1"
  end
end

Paperclip.interpolates :mission do |attachment, style|
  attachment.instance.mission.compact_name
end

Paperclip.interpolates :locale do |attachment, style|
  I18n.locale
end
