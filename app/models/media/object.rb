class Media::Object < ActiveRecord::Base
  belongs_to :answer

  has_attached_file :item
  validates_attachment_presence :item

  # delegate :url, to: :item
  delegate :mission, to: :answer

  scope :expired, -> { where(answer_id: nil).where('created_at < ?', 12.hours.ago) }

  def url(style = nil)
    item.url(style) if item.present?
  end

  def download_url
    dl_url = url
    separator = (dl_url =~ /\?/) ? "&" : "?"
    "#{dl_url}#{separator}dl=1"
  end

  def media_class(type)
    case type
    when 'audio'
      return Media::Audio
    when 'video'
      return Media::Video
    when 'image'
      return Media::Image
    else
      raise "A valid media type must be specified"
    end
  end
end

Paperclip.interpolates :mission do |attachment, style|
  attachment.instance.mission.compact_name
end

Paperclip.interpolates :locale do |attachment, style|
  I18n.locale
end
