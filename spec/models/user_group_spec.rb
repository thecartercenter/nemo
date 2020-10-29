# frozen_string_literal: true

# rubocop:disable Layout/LineLength
# == Schema Information
#
# Table name: user_groups
#
#  id         :uuid             not null, primary key
#  name       :string(255)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  mission_id :uuid             not null
#
# Indexes
#
#  index_user_groups_on_mission_id           (mission_id)
#  index_user_groups_on_name_and_mission_id  (name,mission_id) UNIQUE
#
# Foreign Keys
#
#  user_groups_mission_id_fkey  (mission_id => missions.id) ON DELETE => restrict ON UPDATE => restrict
#
# rubocop:enable Layout/LineLength

require "rails_helper"

describe UserGroup do
  let(:user_group) { create(:user_group) }

  it "has a valid factory" do
    expect(user_group).to be_valid
  end

  context "within the same mission" do
    let(:user_group) { create(:user_group, name: "Duplicate") }
    let(:user_group2) { build(:user_group, name: "Duplicate") }

    it "disallows repeat names" do
      expect(user_group).to be_valid
      expect(user_group2).to_not(be_valid)
    end
  end

  context "within different missions" do
    let(:mission1) { get_mission }
    let(:mission2) { create(:mission) }
    let(:user_group) { create(:user_group, name: "Duplicate", mission: mission1) }
    let(:user_group2) { create(:user_group, name: "Duplicate", mission: mission2) }

    it "allows repeat names" do
      expect(user_group).to be_valid
      expect(user_group2).to be_valid
    end
  end

  describe "destroy" do
    let(:group) { create(:user_group, users: [create(:user)]) }
    let!(:broadcast) { create(:broadcast, recipient_groups: [group]) }
    let!(:form) { create(:form, sms_relay: true, recipient_groups: [group]) }

    it "destroys appropriate associated objects" do
      # First ensure the objects exist
      expect(broadcast.broadcast_addressings.count).to eq(1)
      expect(form.form_forwardings.count).to eq(1)

      # Then destroy and ensure they are gone.
      group.destroy
      expect(broadcast.broadcast_addressings.count).to eq(0)
      expect(form.form_forwardings.count).to eq(0)
    end
  end
end
