# frozen_string_literal: true

class ApplicationJob < ActiveJob::Base
  include Rails.application.routes.url_helpers
end
