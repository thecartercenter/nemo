# frozen_string_literal: true

# rubocop:disable Layout/LineLength
# == Schema Information
#
# Table name: tags
#
#  id         :uuid             not null, primary key
#  name       :string(64)       not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  mission_id :uuid
#
# Indexes
#
#  index_tags_on_mission_id           (mission_id)
#  index_tags_on_name_and_mission_id  (name,mission_id) UNIQUE
#
# Foreign Keys
#
#  tags_mission_id_fkey  (mission_id => missions.id) ON DELETE => restrict ON UPDATE => restrict
#
# rubocop:enable Layout/LineLength

require "rails_helper"

describe Tag do
  it "should force name to lowercase" do
    tag = create(:tag, name: "ABC")
    expect(tag.reload.name).to eq("abc")
  end
end
