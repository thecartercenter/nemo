require 'rails_helper'

describe 'response checkout' do
  it "user should get a notice when response is locked by another user" do
    user = get_user
    user_b = create(:user, name: "first user to lock")
    resp = create(:response)

    # checkout response by another user
    resp.check_out!(user_b)

    # login with user and edit response
    login(user)
    get_s("/en/m/#{get_mission.compact_name}/responses/#{resp.id}/edit")

    # check for warning that response was checked out by another user
    expect(flash[:notice].gsub(/#{I18n.t("response.checked_out")} /, '')).to eq(user_b.name)
  end

  it "user should not get a notice when a checked out response is no longer valid" do
    user = get_user
    user_b = create(:user, name: "first user to lock")
    resp = create(:response)

    # go just outside the valid lock time and checkout response by another user
    Timecop.freeze((Response::LOCK_OUT_TIME + 1.minutes).ago) do
      resp.check_out!(user_b)
    end

    # login with user and edit response
    login(user)
    get_s("/en/m/#{get_mission.compact_name}/responses/#{resp.id}/edit")

    # check that there is no warning
    expect(flash[:notice]).to be_nil
  end
end
