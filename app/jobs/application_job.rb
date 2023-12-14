# frozen_string_literal: true

# https://api.rubyonrails.org/classes/ActiveJob/Exceptions/ClassMethods.html
class ApplicationJob < ActiveJob::Base
  include Rails.application.routes.url_helpers

  around_perform do |_job, block|
    Setting.with_cache(&block)
  end

  # Skip the job if the subject of the job has already been destroyed.
  discard_on ActiveJob::DeserializationError do |job, error|
    Rails.logger.error("Skipping #{job.class}: #{error.message}")
    Sentry.add_breadcrumb(Sentry::Breadcrumb.new(message: error.message))
    Sentry.capture_message("#{job.class} DeserializationError")
  end
end
