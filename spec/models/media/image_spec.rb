require "spec_helper"

describe Media::Image do
  it_behaves_like "has a uuid"
  include_examples "accepts file extensions", %w(jpg png)
  include_examples "rejects file extensions", %w(tiff)
  include_examples "rejects file types", %w(audio video)
end
