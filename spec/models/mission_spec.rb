# frozen_string_literal: true

require "rails_helper"

describe Mission do
  it "has a valid factory" do
    create(:mission)
  end

  it "creates a Setting instance on create" do
    mission = create(:mission)

    # Ensure it was created *on create*, not just-in-time on access.
    expect(Setting.where(mission_id: mission.id).count).to eq(1)
  end
end
