# frozen_string_literal: true

require "rails_helper"

describe Media::Video do
  include_context "media helpers"
  include_examples "accepts file types", %w[video]
  include_examples "rejects file types", %w[image audio]
end
