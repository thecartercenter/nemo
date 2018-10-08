# frozen_string_literal: true

require "rails_helper"

feature "operations panel" do
  let!(:admin) { create(:admin) }
  let(:mission) { get_mission }
  let!(:mission_operation) { create(:operation, mission_id: mission.id) }
  let!(:non_mission_operation) { create(:operation, mission_id: nil) }

  before do
    login(admin)
  end

  scenario "in mission mode, displays only operations that belong to mission" do
    visit("/en/m/#{mission.compact_name}/operations")
    expect(page).to have_selector("#operation_#{mission_operation.id}")
    expect(page).to_not(have_selector("#operation_#{non_mission_operation.id}"))
  end

  scenario "in admin mode, displays all operations " do
    visit("/en/admin/operations")
    expect(page).to have_selector("#operation_#{mission_operation.id}")
    expect(page).to have_selector("#operation_#{non_mission_operation.id}")
  end
end
