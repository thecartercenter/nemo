# frozen_string_literal: true

require "rails_helper"

describe "user regenerable fields", js: true do
  include_context "regenerable fields"

  let!(:user) { create(:user) }
  let!(:mission) { get_mission }

  before do
    login(user)
  end

  describe "sms auth code" do
    scenario "can regenerate" do
      visit("/en/m/#{mission.compact_name}/users/#{user.id}/edit")
      expect_token_regenerated(".user_sms_auth_code")
    end
  end
end
