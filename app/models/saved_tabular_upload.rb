# frozen_string_literal: true

# rubocop:disable Layout/LineLength
# == Schema Information
#
# Table name: saved_uploads
#
#  id         :uuid             not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# rubocop:enable Layout/LineLength

# A model for a spreadsheet upload.
class SavedTabularUpload < SavedUpload
  # Windows uses ms-excel as content type for CSV files (at least Windows 10; regardless of browser).
  validates :file, content_type: %w[text/csv application/csv application/vnd.ms-excel]
  validate :csv_filename

  def csv_filename
    return if /\.csv\z/.match?(file.filename.to_s)
    errors.add(:file, :invalid) # This isn't actually shown to the user.
  end
end
