require "rails_helper"

describe UserGroup do
  let(:user_group) { create(:user_group) }

  it "has a valid factory" do
    expect(user_group).to be_valid
  end

  context "within the same mission"do
    let(:user_group) { create(:user_group, name: "Duplicate") }
    let(:user_group2) { build(:user_group, name: "Duplicate") }

    it "disallows repeat names" do
      expect(user_group).to be_valid
      expect(user_group2).to_not be_valid
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
      expect(broadcast.broadcast_addressings.count).to eq 1
      expect(form.form_forwardings.count).to eq 1

      # Then destroy and ensure they are gone.
      group.destroy
      expect(broadcast.broadcast_addressings.count).to eq 0
      expect(form.form_forwardings.count).to eq 0
    end
  end
end
