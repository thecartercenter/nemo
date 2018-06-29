# frozen_string_literal: true

require "rails_helper"

describe Media::Image do
  include_context "media helpers"
  include_examples "accepts file extensions", %w[jpg png]
  include_examples "rejects file extensions", %w[tiff]
  include_examples "rejects file types", %w[audio video]
end
