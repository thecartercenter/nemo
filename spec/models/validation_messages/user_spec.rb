require 'rails_helper'

describe User do
  context 'with assignment validation error' do
    before do
      @user = build(:user)
      @user.assignments[0].mission = nil
      @user.assignments[0].role = nil
      @user.save
    end

    it 'assignment validation message should be correct' do
      expect(@user.errors['assignments.role']).to eq ['is required.']
      expect(@user.errors['assignments.mission']).to eq ['is required.']
    end
  end

  describe "destroy" do
    let(:user) { create(:user) }
    let!(:broadcast) { create(:broadcast, recipient_users: [user]) }
    let!(:form) { create(:form, sms_relay: true, recipient_users: [user]) }

    it "destroys appropriate associated objects" do
      # First ensure the objects exist
      expect(broadcast.broadcast_addressings.count).to eq 1
      expect(form.form_forwardings.count).to eq 1

      # Then destroy and ensure they are gone.
      user.destroy
      expect(broadcast.broadcast_addressings.count).to eq 0
      expect(form.form_forwardings.count).to eq 0
    end
  end
end
