require "spec_helper"

describe "accessing forms" do

  before do
    @mission = FactoryGirl.create(:mission, name: "awesome")
    @form1 = @mission.forms.create(name: "test1", access_level: AccessLevel::PRIVATE)
    @form2 = @mission.forms.create(name: "test2", access_level: AccessLevel::PUBLIC)
    @api_user = FactoryGirl.create(:user)
  end


  context "Public Forms are returned for a mission" do

    before do
      get api_v1_misson_forms_path(mission_name: @mission.name), {}, {'HTTP_AUTHORIZATION' => "Token token=#{@api_user.api_key}"}
      @forms = parse_json(response.body)
    end

    it "should find 1 public form" do
      expect(@forms.size).to eq 1
    end

  end

  context "with invalid mission" do
    before do
      get api_v1_misson_forms_path(mission_name: 'junk'), {}, {'HTTP_AUTHORIZATION' => "Token token=#{@api_user.api_key}"}
    end

    it "returns 404" do
      expect(response.status).to eq(404)
    end
  end

  context "View metadata on a form" do

    before do
      q1 = FactoryGirl.create(:question, mission: @mission, access_level: AccessLevel::PUBLIC)
      q2 = FactoryGirl.create(:question, mission: @mission, access_level: AccessLevel::PUBLIC)
      q3 = FactoryGirl.create(:question, mission: @mission, access_level: AccessLevel::PRIVATE)
      @form1.questions.push(q1, q2, q3)
      get api_v1_form_path(@form1.id), {}, {'HTTP_AUTHORIZATION' => "Token token=#{@api_user.api_key}"}
      @form_json = parse_json(response.body)
    end

    it "should have fields for form" do
      expect(@form_json.keys.include?(:name)).to be_true
    end

    it "should include 2 questions" do
      expect(@form_json[:questions].size).to eq 2
    end

    it "should include question field name" do
      expect(@form_json[:questions].first.keys.include?(:name)).to be_true
    end

  end

end
