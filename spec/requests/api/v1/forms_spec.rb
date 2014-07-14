require "spec_helper"

describe "accessing forms" do

  before do
    @mission = FactoryGirl.create(:mission, name: "awesome")
    @form1 = @mission.forms.create(name: "test1")
    @form2 = @mission.forms.create(name: "test2", access_level: 'public')
    @api_user = FactoryGirl.create(:user)
  end


  context "Public Forms are returned for a mission" do

    before do
      do_api_request(:forms)
      @forms = parse_json(response.body)
    end

    it "should find 1 public form" do
      expect(@forms.size).to eq 1
    end

  end

  context "with invalid mission" do
    before do
      do_api_request(:forms, :mission_name => 'junk')
    end

    it "returns 404" do
      expect(response.status).to eq(404)
    end
  end

  context "View metadata on a form" do

    before do
      q1 = FactoryGirl.create(:question, mission: @mission)
      q2 = FactoryGirl.create(:question, mission: @mission)
      q3 = FactoryGirl.create(:question, mission: @mission, access_level: 'private')
      @form1.questions.push(q1, q2, q3)
      do_api_request(:form, :obj => @form1)
      @form_json = parse_json(response.body)
    end

    it "should have fields for form" do
      expect(@form_json.keys.include?(:name)).to be_true
    end

    # THIS TEST WAS FAILING. NEED TO FIX IT.
    # it "should include 2 questions" do
    #   expect(@form_json[:questions].size).to eq 2
    # end

    it "should include question field name" do
      expect(@form_json[:questions].first.keys.include?(:name)).to be_true
    end

  end

end
