# frozen_string_literal: true

# A model for a csv or xlsx file upload, managed by Paperclip
class SavedTabularUpload < SavedUpload
  validates_attachment_file_name :file, matches: /\.(csv|xlsx)\Z/i
end
