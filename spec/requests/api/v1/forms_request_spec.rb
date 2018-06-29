require "rails_helper"

describe "forms API requests" do
  include_context "api"

  describe "list forms" do
    before do
      create(:form, name: "Form 1", mission: mission, access_level: "public")
      create(:form, name: "Form 2", mission: mission, access_level: "protected")
      create(:form, name: "Form 3", mission: mission)
      form4 = create(:form, name: "Form 4", mission: mission, access_level: "protected")
      form4.whitelistings.create(user: user)
    end

    it "should return a list of forms the user can see" do
      get "/api/v1/m/mission1/forms", headers: headers
      expect(response).to have_http_status(200)
      expect(json.size).to eq 2
      expect(json.first.keys.sort).to eq %w(id name responses_count)
      expect(json.map{ |f| f["name"] }).to eq ["Form 1", "Form 4"]
    end

    it "should result in 401 if wrong api token" do
      get "/api/v1/m/mission1/forms", headers: bad_headers
      expect(response).to have_http_status(401)
      expect(json["errors"]).to eq %w(invalid_api_token)
    end
  end

  describe "get form" do
    let(:form){ create(:form, name: "Form 1", mission: mission, access_level: "public",
      question_types: %w(integer integer)) }

    it "should return appropriate json" do
      get "/api/v1/m/mission1/forms/#{form.id}", headers: headers
      expect(response).to have_http_status(200)
      expect(json.keys.sort).to eq %w(id name questions responses_count)
      expect(json["questions"].size).to eq 2
      expect(json["questions"].first.keys.sort).to eq %w(code id name)
    end
  end
end
