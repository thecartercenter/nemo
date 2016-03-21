require "spec_helper"
require "support/media_spec_helpers"

describe "odk media submissions", type: :request, clean_with_truncation: true do
  include ODKSubmissionSupport

  context "with single part" do
    before do
      @form = create(:form, question_types: %w(image))
      @form.publish!
      @user = create(:user,role_name: "observer")
      @mission = @user.mission
    end

    it "should successfully process the submission" do
      image = fixture_file_upload(media_fixture("images/the_swing.jpg"), "image/jpeg")
      xml = expectation_file("odk/responses/single_part_media.xml")

      
    end
  end
end
