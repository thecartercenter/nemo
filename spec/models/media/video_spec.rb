require "spec_helper"

describe Media::Video do
  it_behaves_like "has a uuid"
  include_examples "accepts file extensions", %w(3gp mp4 webm mpeg wmv avi)
  include_examples "rejects file extensions", %w(ogv)
  include_examples "rejects file types", %w(image audio)
end
