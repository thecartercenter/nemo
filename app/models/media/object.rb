class Media::Object < ActiveRecord::Base
  belongs_to :answer

  has_attached_file :item
  validates_attachment_presence :item

  delegate :mission, to: :answer
  delegate :url, to: :item, allow_nil: true

  before_save :generate_token

  scope :expired, -> { where(answer_id: nil).where("created_at < ?", 12.hours.ago) }

  def download_url
    dl_url = url
    separator = (dl_url =~ /\?/) ? "&" : "?"
    "#{dl_url}#{separator}token=#{token}&dl=1"
  end

  def token_url(style: nil)
    separator = url =~ /\?/ ? "&" : "?"
    "#{url(style)}#{separator}token=#{token}"
  end

  private

  def generate_token
    self.token = SecureRandom.hex
  end
end

Paperclip.interpolates :mission do |attachment, style|
  attachment.instance.mission.compact_name
end

Paperclip.interpolates :locale do |attachment, style|
  I18n.locale
end
