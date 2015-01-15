require "spec_helper"

feature "send broadcast", js: true, driver: :selenium do
  before do
    @user = create(:user, role_name: 'coordinator', phone: "+1234567890", email: "testemail@example.com")
    @user2 = create(:user, role_name: 'staffer', phone: "+6789012345", email: "testemail2@example.com")
    login(@user)
  end

  scenario "both email and sms" do
    click_link "Broadcasts"
    click_link "Send Broadcast"
    check "selected_#{@user.id}"
    check "selected_#{@user2.id}"
    click_link "Send Broadcast"
    select "Both SMS and email", from: "broadcast_medium"
    select "Main phone only", from: "broadcast_which_phone"
    fill_in "broadcast_body", with: "Test message"
    click_button "Send"
    expect(page).to have_text "Broadcast sent successfully"
  end
end
