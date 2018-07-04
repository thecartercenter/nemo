require "rails_helper"
require "fileutils"

describe UploadSaver do
  before do
    FileUtils.mkdir_p(Rails.root.join("tmp", "uploads"))
  end

  describe "save_file" do
    let(:uploaded) { Rack::Test::UploadedFile.new(fixture("", "file.txt"), "text/plain") }
    let(:saved_path) { UploadSaver.new.save_file(uploaded) }

    it "saves file" do
      expect(saved_path).to match(/\A.+\.txt\z/)
      expect(File.read(saved_path)).to eq "Stuff\n"
    end
  end

  describe "cleanup_old_files" do
    let(:old_upload_path) { UploadSaver::STORAGE_PATH.join("foo.txt") }
    let(:new_upload_path) { UploadSaver::STORAGE_PATH.join("bar.txt") }

    before do
      FileUtils.touch(new_upload_path)
      FileUtils.touch(old_upload_path)

      old_time = Time.now - 32.days
      File.utime(old_time, old_time, old_upload_path)

      UploadSaver.new.cleanup_old_files
    end

    it "deletes old uploads only" do
      expect(File.exists?(new_upload_path)).to be true
      expect(File.exists?(old_upload_path)).to be false
    end
  end
end
