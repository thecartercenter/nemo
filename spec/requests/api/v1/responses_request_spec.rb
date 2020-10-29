# frozen_string_literal: true

require "rails_helper"

describe "response API requests" do
  include_context "api"

  describe "list responses by form" do
    include_context "api form with responses"

    it "should return appropriate json sorted newest first" do
      get "/api/v1/m/mission1/responses?form_id=#{@form.id}", headers: headers
      expect(response).to have_http_status(:ok)
      expect(json.size).to eq(3)
      expect(json.first.keys.sort).to eq(%w[answers created_at id submitter updated_at])
      expect(json.first["answers"].size).to eq(2)
      expect(json.map { |r| r["answers"].first["value"] }).to contain_exactly(3, 2, 1)
      expect(json.first["answers"].first.keys.sort).to eq(%w[code id question value])
    end

    it "should restrict by date/time" do
      t1 = (Time.zone.now - 7.days).iso8601
      t2 = (Time.zone.now - 3.days).iso8601
      get "/api/v1/m/mission1/responses?form_id=#{@form.id}&created_before=#{t2}&created_after=#{t1}",
        headers: headers
      expect(response).to have_http_status(:ok)
      expect(json.size).to eq(1)
      # answers should be sorted by rank, expect integer question first
      expect(json.first["answers"].first["value"]).to eq(2)
    end
  end
end
