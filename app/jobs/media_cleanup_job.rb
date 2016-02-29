class MediaCleanupJob < ApplicationJob
  queue_as :default

  def perform
    Media::Object.expired.find_each do |media|
      media.destroy
    end
  end
end
