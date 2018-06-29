require "rails_helper"

describe "answers API requests" do
  include_context "api"

  describe "list answers by form" do
    include_context "api_form_with_responses"

    it "should return appropriate json sorted newest first" do
      get "/api/v1/m/mission1/answers?form_id=#{@form.id}&question_id=#{@form.questions[0].id}", headers: headers
      expect(response).to have_http_status(200)
      expect(json.size).to eq 3
      expect(json.first.keys.sort).to eq %w(id value)
      expect(json.map{ |a| a["value"] }).to eq [3, 2, 1]
    end

    it "should not return answers to private question" do
      get "/api/v1/m/mission1/answers?form_id=#{@form.id}&question_id=#{@form.questions[2].id}", headers: headers
      expect(response).to have_http_status(403)
    end

    it "should restrict by date/time" do
      t1 = (Time.now - 7.days).iso8601
      t2 = (Time.now - 3.days).iso8601
      get "/api/v1/m/mission1/answers?form_id=#{@form.id}&question_id=#{@form.questions[0].id}" <<
        "&created_before=#{t2}&created_after=#{t1}", headers: headers
      expect(response).to have_http_status(200)
      expect(json.size).to eq 1
      expect(json.first["value"]).to eq 2
    end
  end
end
