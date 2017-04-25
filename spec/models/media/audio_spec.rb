require "spec_helper"

describe Media::Audio do
  it_behaves_like "has a uuid"
  include_examples "accepts file extensions", %w(ogg mp3 wav webm)
  include_examples "rejects file extensions", %w(m4a opus flac)
  include_examples "rejects file types", %w(image video)
end
