require "spec_helper"

describe UserGroup do
  it "has a valid factory" do
    user_group = create(:user_group)
    expect(user_group).to be_valid
  end
end
