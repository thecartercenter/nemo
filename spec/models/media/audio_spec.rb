# frozen_string_literal: true

require "rails_helper"

describe Media::Audio do
  include_context "media helpers"
  include_examples "accepts file types", %w[audio]
  include_examples "rejects file types", %w[image video]
end
