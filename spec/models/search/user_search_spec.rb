# tests the search functionality for the user model
require "spec_helper"

describe User do
  describe "search" do
    let!(:first_group) { create(:user_group) }
    let!(:second_group) { create(:user_group) }
    let!(:first_user) { create(:user_group_assignment, user_group: first_group).user }
    let!(:second_user) { create(:user_group_assignment, user_group: first_group).user }
    let!(:third_user) { create(:user_group_assignment, user_group: second_group).user }
    subject { User.with_groups.do_search(User.with_groups, %[group:"#{group_sought.name}"]).to_a }

    context "searching for first group" do
      let(:group_sought) { first_group }

      it "should work" do
        expect(subject).to contain_exactly(first_user, second_user)
      end
    end

    context "searching for first group" do
      let(:group_sought) { second_group }

      it "should work" do
        expect(subject).to contain_exactly(third_user)
      end
    end
  end
end
