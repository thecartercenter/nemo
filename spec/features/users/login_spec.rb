# frozen_string_literal: true

require "rails_helper"

feature "login", js: true do
  let(:user) { create(:user) }

  before do
    # Specs have security off by default.
    ActionController::Base.allow_forgery_protection = true
  end

  after do
    ActionController::Base.allow_forgery_protection = false
  end

  it "should login and show welcome" do
    real_login(user)
    expect(page).to have_current_path(
      mission_root_path(mission_name: get_mission.compact_name, locale: "en")
    )
  end

  it "should return a user-friendly error when stale" do
    visit(login_path(locale: "en"))
    page.execute_script("$('[name=\"authenticity_token\"]').val('invalid')")
    real_login(user, skip_visit: true)
    expect(page).to have_current_path(login_path(locale: "en"))
    expect(page).to have_content("request has expired")
  end
end
