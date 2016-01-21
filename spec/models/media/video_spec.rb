require 'spec_helper'

describe Media::Video do
  %w(3gp mp4 webm mpeg wmv avi).each do |extension|
    context "with #{extension}" do
      let(:media_file) { build(:media_video, extension.to_sym) }

      it 'is valid' do
        expect(media_file).to be_valid
      end
    end
  end
end
