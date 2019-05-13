# frozen_string_literal: true

require "rails_helper"

feature "login instructions" do
  let(:enumerator) { create(:user, role_name: :enumerator, mission: mission) }
  let(:mission) { get_mission }
  let(:actor) { create(:admin, mission: mission) }

  around do |example|
    with_env("STUB_PASSWORD" => "testpass") { example.run }
  end

  before do
    login(actor)
  end

  scenario "regular instructions mask password", js: true do
    visit "/en/m/#{mission.compact_name}/users/#{enumerator.id}/login-instructions"
    expect(page).to have_content("Login Instructions")
    expect(page).not_to have_content("testpass")
    expect(evaluate_script("$('.masked').is(':visible')")).to eq(true)
  end

  scenario "printable instructions do not mask password", js: true do
    visit "/en/m/#{mission.compact_name}/users/#{enumerator.id}/login-instructions?medium=print"
    expect(page).to have_content("Login Instructions")
    expect(page).to have_content("testpass")
    expect(evaluate_script("$('.unmasked').is(':visible')")).to eq(true)
  end
end
