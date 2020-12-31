# frozen_string_literal: true

# rubocop:disable Layout/LineLength
# == Schema Information
#
# Table name: saved_uploads
#
#  id                :uuid             not null, primary key
#  file_content_type :string           not null
#  file_file_name    :string           not null
#  file_file_size    :integer          not null
#  file_updated_at   :datetime         not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
# rubocop:enable Layout/LineLength

require "rails_helper"
require "fileutils"

describe SavedUpload do
  let(:uploaded) { Rack::Test::UploadedFile.new(fixture("", "file.txt"), "text/plain") }

  it "saves file" do
    saved_upload = described_class.create!(file: uploaded)
    expect(saved_upload.file.download).to eq("Stuff\n")
  end

  describe "#cleanup_old_uploads" do
    let!(:saved_upload1) { SavedUpload.create!(file: uploaded, created_at: 32.days.ago) }
    let!(:saved_upload2) { SavedUpload.create!(file: uploaded, created_at: 31.days.ago) }
    let!(:saved_upload3) { SavedUpload.create!(file: uploaded, created_at: 28.days.ago) }

    it "deletes old uploads only" do
      described_class.cleanup_old_uploads
      expect(described_class.all.to_a).to eq([saved_upload3])
    end
  end
end
