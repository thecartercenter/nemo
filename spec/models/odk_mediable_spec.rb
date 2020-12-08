# frozen_string_literal: true

require "rails_helper"

describe "media_prompt content types and filenames" do
  describe "validations" do
    subject(:question) { build(:question) }

    before do
      question.media_prompt.attach(io: media_file, filename: File.basename(media_file))
    end

    describe "acceptable types" do
      context "ogg audio" do
        let(:media_file) { audio_fixture("powerup.ogg") }
        it { is_expected.to be_valid }
      end

      context "wav audio" do
        let(:media_file) { audio_fixture("powerup.wav") }
        it { is_expected.to be_valid }
      end

      context "mp3 audio" do
        let(:media_file) { audio_fixture("powerup.mp3") }
        it { is_expected.to be_valid }
      end

      context "flac audio" do
        let(:media_file) { audio_fixture("powerup.flac") }
        it { is_expected.to be_valid }
      end

      context "mp4 h.264 video" do
        let(:media_file) { video_fixture("jupiter.mp4") }
        it { is_expected.to be_valid }
      end

      context "png image" do
        let(:media_file) { image_fixture("the_swing.png") }
        it { is_expected.to be_valid }
      end

      context "jpg image" do
        let(:media_file) { image_fixture("the_swing.jpg") }
        it { is_expected.to be_valid }
      end
    end

    describe "unacceptable extensions" do
      context "opus audio" do
        let(:media_file) { audio_fixture("powerup.opus") }
        it { is_expected.to have_errors(media_prompt: "The file type is invalid.") }
      end

      context "avi video" do
        let(:media_file) { video_fixture("jupiter.avi") }
        it { is_expected.to have_errors(media_prompt: "The file type is invalid.") }
      end

      context "ogg/ogv video" do
        let(:media_file) { video_fixture("jupiter.ogv") }
        it { is_expected.to have_errors(media_prompt: "The file type is invalid.") }
      end

      context "tiff image" do
        let(:media_file) { image_fixture("the_swing.tiff") }
        it { is_expected.to have_errors(media_prompt: "The file type is invalid.") }
      end
    end

    describe "unacceptable mime types" do
      context "non-mp4 video with mp4 extension" do
        let(:media_file) { video_fixture("notmp4.mp4") }
        it { is_expected.to have_errors(media_prompt: "The file type is invalid.") }
      end
    end
  end

  describe "media_type" do
    subject(:question) { build(:question, media_prompt_file_name: filename).media_prompt_type }

    context "audio" do
      let(:filename) { "foo.ogg" }
      it { is_expected.to eq(:audio) }
    end

    context "video" do
      let(:filename) { "foo.mp4" }
      it { is_expected.to eq(:video) }
    end

    context "image" do
      let(:filename) { "foo.png" }
      it { is_expected.to eq(:image) }
    end

    context "invalid" do
      let(:filename) { "foo.bar" }
      it { is_expected.to be_nil }
    end
  end
end
