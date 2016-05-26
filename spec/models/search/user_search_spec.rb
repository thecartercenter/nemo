# tests the search functionality for the user model
require "spec_helper"
include SphinxSupport

describe User do
  describe "search" do
    let!(:first_group) { create(:user_group) }
    let!(:second_group) { create(:user_group) }
    let!(:first_user) { create(:user_group_assignment, user_group: first_group).user }
    let!(:second_user) { create(:user_group_assignment, user_group: first_group).user }
    let!(:third_user) { create(:user_group_assignment, user_group: second_group).user }

    it "group qualifier should work" do
      expect(group_search(first_group)).to eq [first_user, second_user]
      expect(group_search(second_group)).to eq [third_user]
    end
  end
end

def perform_search(query)
  results = User.with_groups.do_search(User.with_groups, query)
  results.to_a
end

def group_search(group)
  perform_search(%[group:"#{group.name}"])
end
