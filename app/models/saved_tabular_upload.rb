# frozen_string_literal: true

# == Schema Information
#
# Table name: saved_uploads
#
#  id                :uuid             not null, primary key
#  file_content_type :string           not null
#  file_file_name    :string           not null
#  file_file_size    :integer          not null
#  file_updated_at   :datetime         not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#


# A model for a csv or xlsx file upload, managed by Paperclip
class SavedTabularUpload < SavedUpload
  validates_attachment_file_name :file, matches: /\.(csv|xlsx)\Z/i
end
