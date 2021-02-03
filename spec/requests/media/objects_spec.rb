# frozen_string_literal: true

require "rails_helper"

describe "media object requests" do
  let(:mission) { create(:mission, name: "Mission 1") }
  let(:user) { create(:user, mission: mission) }
  let(:form) { create(:form, mission: mission, question_types: %w[image]) }

  before do
    login(user)
  end

  describe "upload media object" do
    context "with audio" do
      let(:form) { create(:form, mission: mission, question_types: %w[audio]) }

      it "uploads audio files" do
        file = Rack::Test::UploadedFile.new(audio_fixture("powerup.mp3"), "audio/mpeg")
        post(media_objects_path(mission_name: mission.compact_name, type: "audios"), params: {upload: file})
        expect(response).to have_http_status(:created)
      end
    end

    context "with video" do
      let(:form) { create(:form, mission: mission, question_types: %w[video]) }

      it "uploads video files" do
        file = Rack::Test::UploadedFile.new(video_fixture("jupiter.avi"), "video/x-msvideo")
        post(media_objects_path(mission_name: mission.compact_name, type: "videos"), params: {upload: file})
        expect(response).to have_http_status(:created)
      end
    end

    context "with images" do
      let(:form) { create(:form, mission: mission, question_types: %w[image]) }

      it "uploads image files" do
        file = Rack::Test::UploadedFile.new(image_fixture("the_swing.jpg"), "image/jpeg")
        post(media_objects_path(mission_name: mission.compact_name, type: "images"), params: {upload: file})
        expect(response).to have_http_status(:created)
      end
    end

    context "with media type mismatch" do
      let(:form) { create(:form, mission: mission, question_types: %w[image]) }

      it "returns 422 on failure" do
        file = Rack::Test::UploadedFile.new(audio_fixture("powerup.mp3"))
        post(media_objects_path(mission_name: mission.compact_name, type: "images"), params: {upload: file})
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "delete media object" do
    let(:media_file) { create(:media_image) }

    it "returns empty 204 on success" do
      delete(media_object_path(media_file, mission_name: mission.compact_name, type: "images"))
      expect(response).to have_http_status(:no_content)
    end
  end
end
