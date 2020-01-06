# frozen_string_literal: true

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
    SavedUpload.cleanup_old_uploads
  end
end
