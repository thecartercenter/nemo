require "spec_helper"

describe UserGroupAssignment do
  it_behaves_like "has a uuid"

  it "has a valid factory" do
    user_group_assignment = create(:user_group_assignment)
    expect(user_group_assignment).to be_valid
  end
end
