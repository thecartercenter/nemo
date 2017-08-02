module UploadProcessable
  extend ActiveSupport::Concern

  protected

  # Stores uploaded file in a non-temporary file either 1) so that it hangs around
  # long enough for our operation to process it, or 2) so that we can examine
  # it in case of error, or both.
  def store_uploaded_file(uploaded)
    file_extension = File.extname(uploaded.original_filename)
    file_name = "#{controller_name}-#{SecureRandom.uuid}#{file_extension}"
    stored_path = Rails.root.join('tmp', 'uploads', file_name).to_s

    FileUtils.mkdir_p(File.dirname(stored_path), mode: 0755)
    File.open(stored_path, 'wb') do |file|
      file.write(uploaded.read)
    end

    stored_path
  end
end
