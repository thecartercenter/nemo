# frozen_string_literal: true

require "rails_helper"

describe Media::Video do
  include_context "media helpers"
  include_examples "accepts file extensions", %w[3gp mp4 webm mpeg wmv avi]
  include_examples "rejects file extensions", %w[ogv]
  include_examples "rejects file types", %w[image audio]
end
