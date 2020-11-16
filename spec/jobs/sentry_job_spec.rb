# frozen_string_literal: true

require "rails_helper"
require "json"
require "open-uri"

describe SentryJob do
  around do |example|
    Raven.configure { |c| c.dsn = "http://public@example.com/project-id" }
    example.run
    Raven.configure { |c| c.dsn = nil }
  end

  it "gets created automatically" do
    VCR.use_cassette("sentry", match_requests_on: %i[method uri host path]) do
      begin
        1 / 0
      rescue ZeroDivisionError => e
        Raven.capture_exception(e)
      end
      Delayed::Worker.new.work_off
    end
  end
end
