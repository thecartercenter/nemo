# frozen_string_literal: true

# rubocop:disable Layout/LineLength
# == Schema Information
#
# Table name: missions
#
#  id           :uuid             not null, primary key
#  compact_name :string(255)      not null
#  locked       :boolean          default(FALSE), not null
#  name         :string(255)      not null
#  shortcode    :string(255)      not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_missions_on_compact_name  (compact_name) UNIQUE
#  index_missions_on_shortcode     (shortcode) UNIQUE
#
# rubocop:enable Layout/LineLength

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
