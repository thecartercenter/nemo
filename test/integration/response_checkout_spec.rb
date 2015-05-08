require 'spec_helper'

describe 'ResponseCheckout' do

  it "user should get a notice when response is locked by another user" do
    user = get_user
    user_b = create(:user, :name => "first user to lock")
    resp = create(:response)

    # checkout response by another user
    resp.check_out!(user_b)

    # login with user and edit response
    login(user)
    get("/en/m/#{get_mission.compact_name}/responses/#{resp.id}/edit")
    assert_response :success

    # check for warning that response was checked out by another user
    assert flash[:notice]
    assert_equal user_b.name, flash[:notice].gsub(/#{I18n.t("response.checked_out")} /, '')
  end

  it "user should not get a notice when a checked out response is no longer valid" do
    user = get_user
    user_b = create(:user, :name => "first user to lock")
    resp = create(:response)

    # go just outside the valid lock time and checkout response by another user
    Timecop.freeze((Response::LOCK_OUT_TIME + 1.minutes).ago) do
      resp.check_out!(user_b)
    end

    # login with user and edit response
    login(user)
    get("/en/m/#{get_mission.compact_name}/responses/#{resp.id}/edit")
    assert_response :success

    # check that there is no warning
    assert_nil flash[:notice]
  end
end
