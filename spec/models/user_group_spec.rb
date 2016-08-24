require "spec_helper"

describe UserGroup do
  it "has a valid factory" do
    user_group = create(:user_group)
    expect(user_group).to be_valid
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
