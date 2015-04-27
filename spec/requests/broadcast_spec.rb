require 'spec_helper'

describe "sending a broadcast" do
  before do
    @user = create(:user, role_name: 'staffer')
    @user2 = create(:user, role_name: 'observer')
    login(@user)
  end

  it "should work" do
    post "/en/m/#{get_mission.compact_name}/broadcasts",
      broadcast: {
        recipient_ids: "#{@user.id},#{@user2.id}",
        medium: "sms_only",
        which_phone: "main_only",
        body: "test"
      }
    expect(response).to be_success
    expect(configatron.outgoing_sms_adapter.deliveries.size).to eq 2
  end
end
