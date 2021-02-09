# frozen_string_literal: true

class ApplicationJob < ActiveJob::Base
  include Rails.application.routes.url_helpers

  around_perform do |_job, block|
    Setting.with_cache(&block)
  end
end
