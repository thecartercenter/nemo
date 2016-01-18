class Media::Object < ActiveRecord::Base
  belongs_to :answer

  has_attached_file :item
  validates_attachment_presence :item
  validates_attachment_content_type :item, content_type: %r{\A(image|audio|video)/.*\Z}

  delegate :url, to: :item
end
