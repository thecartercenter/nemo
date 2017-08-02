require "spec_helper"
require "fileutils"

describe CleanupJob do
  let(:old_upload_path) { UploadProcessable::STORAGE_PATH.join("foo.txt") }
  let(:new_upload_path) { UploadProcessable::STORAGE_PATH.join("bar.txt") }

  before do
    FileUtils.touch(new_upload_path)
    FileUtils.touch(old_upload_path)

    old_time = Time.now - 32.days
    File.utime(old_time, old_time, old_upload_path)

    CleanupJob.new.perform
  end

  it "deletes old uploads only" do
    expect(File.exists?(new_upload_path)).to be true
    expect(File.exists?(old_upload_path)).to be false
  end
end
