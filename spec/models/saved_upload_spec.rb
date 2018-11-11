# frozen_string_literal: true

require "rails_helper"
require "fileutils"

describe SavedUpload do
  let(:uploaded) { Rack::Test::UploadedFile.new(fixture("", "file.txt"), "text/plain") }

  it "saves file" do
    saved_upload = described_class.create!(file: uploaded)
    expect(File.read(saved_upload.file.path)).to eq("Stuff\n")
  end

  describe "#cleanup_old_uploads" do
    let!(:saved_upload1) { SavedUpload.create!(file: uploaded, created_at: 32.days.ago) }
    let!(:saved_upload2) { SavedUpload.create!(file: uploaded, created_at: 28.days.ago) }

    it "deletes old uploads only" do
      described_class.cleanup_old_uploads
      expect(described_class.where(id: saved_upload1.id)).to be_empty
      expect(described_class.where(id: saved_upload2.id)).to include(saved_upload2)
    end
  end
end
