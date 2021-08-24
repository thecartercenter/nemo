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

  context "mission mode" do
    scenario "displays only operations that belong to mission" do
      visit("/en/m/#{mission.compact_name}/operations")
      expect(page).to have_selector("#operation_#{mission_operation.id}")
      expect(page).to_not(have_selector("#operation_#{non_mission_operation.id}"))
    end
  end

  context "admin mode" do
    scenario "displays all operations " do
      visit("/en/admin/operations")
      expect(page).to have_selector("#operation_#{mission_operation.id}")
      expect(page).to have_selector("#operation_#{non_mission_operation.id}")
    end
  end

  context "delayed job" do
    let(:error_message) { "Operations are currently not running. Please contact administrator" }

    before do
      stub = double("ok?": result)
      allow(Utils::DelayedJobChecker).to(receive(:instance).and_return(stub))
    end

    context "not running" do
      let(:result) { false }
      scenario "displays error when not running" do
        visit("/en/admin/operations")
        expect(page).to have_content(error_message)
      end
    end

    context "running" do
      let(:result) { true }
      scenario "displays no error when running" do
        visit("/en/admin/operations")
        expect(page).not_to have_content(error_message)
      end
    end
  end

  context "pending operations" do
    scenario "cancel an operation" do
      visit("/en/m/#{mission.compact_name}/operations")
      click_on "Cancel"
      expect(page).to_not(have_content("Cancel"))
      expect(Operation.all.count).to eq(1)
    end
  end

  context "pending and then running operation" do
    scenario "clicking cancel on an operation that then gets picked up shouldn't stop it" do
      visit("/en/m/#{mission.compact_name}/operations")
      mission_operation.job_started_at = Time.zone.now
      click_on "Cancel"
      expect(mission_operation.status).to eq(:running)
      visit("/en/m/#{mission.compact_name}/operations")
      expect(page).to_not(have_content("Cancel"))
    end
  end
end
