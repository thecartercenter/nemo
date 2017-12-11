require "spec_helper"
require "fileutils"

describe "j2me submissions", :odk do

  context "for a valid user and mission" do
    before do
      @mission = FactoryGirl.create(:mission)
      @user = FactoryGirl.create(:user, role_name: :enumerator)
      @submission_url = "/m/#{@mission.compact_name}/submission"
      @form = FactoryGirl.create(:form, mission: @mission, question_types: %w(integer))
      @form.publish!
      @question = @form.questions.first

      # Note that we don't use the noauth system here because that is tested separately.
      submit_j2me_response(auth: true, data: {@question.odk_code => "42"})
    end

    it "should create response successfully" do
      assert_response(201)
      expect(@question.reload.answers.first.value).to eq '42'
    end

    it "should have correct source attrib" do
      expect(@form.reload.responses.first.source).to eq 'j2me'
    end
  end
end
