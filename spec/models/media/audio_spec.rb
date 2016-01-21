require 'spec_helper'

describe Media::Audio do
  let(:media_file) { build(:media_audio) }

  %w(ogg mp3 wav webm).each do |extension|
    context "with #{extension}" do
      let(:media_file) { build(:media_audio, extension.to_sym) }

      it 'is valid' do
        Paperclip.log media_file.errors.inspect if media_file.errors.present?
        expect(media_file).to be_valid
      end
    end
  end

  %w(m4a opus).each do |extension|
    context "with #{extension}" do
      let(:media_file) { build(:media_audio, extension.to_sym) }

      it 'is invalid' do

        expect(media_file).to have(1).error_on(:item_file_name)
      end
    end
  end
end
