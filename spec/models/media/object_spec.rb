require 'rails_helper'

describe Media::Object do
  let(:media_file) { create(:media_image) }

  it "has attachment" do
    expect(media_file).to have_attached_file :item
  end
end
