require "fileutils"

# Saves uploaded files.
class UploadSaver
  STORAGE_PATH = Rails.root.join("tmp", "uploads")

  # Stores uploaded file in the tmp dir either 1) so that it hangs around
  # long enough for our operation to process it, or 2) so that we can examine
  # it in case of error, or both.
  # The file created by Rails is a Tempfile which gets destroyed almost immediately so we can't use that.
  # Returns the path of the stored file.
  def save_file(uploaded)
    file_extension = File.extname(uploaded.original_filename)
    file_name = "#{SecureRandom.uuid}#{file_extension}"
    stored_path = STORAGE_PATH.join(file_name).to_s

    FileUtils.mkdir_p(STORAGE_PATH, mode: 0755)
    File.open(stored_path, 'wb') do |file|
      file.write(uploaded.read)
    end

    # In case anyone else needs to read this.
    uploaded.rewind

    stored_path
  end

  def cleanup_old_files
    Dir.glob(STORAGE_PATH.join("*")).each do |filename|
      File.delete(filename) if Time.now - File.mtime(filename) > 30.days
    end
  end
end
