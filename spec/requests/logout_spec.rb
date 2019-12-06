# frozen_string_literal: true

require "rails_helper"

describe "Logout" do
  let(:user) { create(:user, admin: true) }

  before do
    login(user)
  end

  it "redirect after logout from basic mode should be correct" do
    check_logout_link_and_redirect
  end

  it "redirect after logout from mission mode should be correct" do
    get("/en/m/#{get_mission.compact_name}")
    check_logout_link_and_redirect
  end

  it "redirect after logout from admin mode should be correct" do
    get("/en/admin")
    check_logout_link_and_redirect
  end

  private

  def check_logout_link_and_redirect
    assert_select('#logout_button[href="/en/logout"]', true)
    delete("/en/logout")
    expect(response).to redirect_to("/en/logged-out")
  end
end
