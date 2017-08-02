# Cleans up various bits left around by the app.
class CleanupJob < ApplicationJob
  queue_as :default

  def perform
    cleanup_media
    cleanup_stored_uploads
  end

  private

  def cleanup_media
    Media::Object.expired.find_each(&:destroy)
  end

  def cleanup_stored_uploads
    Dir.glob(UploadProcessable::STORAGE_PATH.join("*")).each do |filename|
      File.delete(filename) if Time.now - File.mtime(filename) > 30.days
    end
  end
end
