# frozen_string_literal: true

# Tests the search functionality for the user model
require "rails_helper"

describe User do
  describe "search" do
    let!(:first_group) { create(:user_group) }
    let!(:second_group) { create(:user_group) }
    let!(:first_user) { create(:user_group_assignment, user_group: first_group).user }
    let!(:second_user) { create(:user_group_assignment, user_group: first_group).user }
    let!(:third_user) { create(:user_group_assignment, user_group: second_group).user }

    # use User.all because rel needs to be an ActiveRecord relation
    subject { User.do_search(User.all, query, scope).to_a }

    context "searching by group" do
      let(:query) { %(group:"#{group_sought.name}") }
      let(:scope) { nil }

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

    context "searching by role" do
      let(:query) { %(role:"#{role_sought}") }
      let(:other_mission) { create(:mission) }

      before(:each) do
        first_user.assignments.create!(mission: get_mission, role: "enumerator")
        first_user.assignments.create!(mission: other_mission, role: "staffer")
        second_user.assignments.create!(mission: get_mission, role: "coordinator")
        third_user.assignments.create!(mission: get_mission, role: "staffer")
      end

      context "in mission" do
        let(:scope) { {mission: get_mission} }

        context "searching for staffer" do
          let(:role_sought)  { "staffer" }

          it "should return all users with staffer role in current mission only" do
            expect(subject).to contain_exactly(third_user)
          end
        end

        context "searching for staffer" do
          let(:role_sought) { "enumerator" }

          it "should return all users with enumerator role in current mission only" do
            expect(subject).to contain_exactly(first_user)
          end
        end
      end

      context "admin mode" do
        let(:scope) { {mission: nil} }

        context "searching for staffer" do
          let(:role_sought) { "staffer" }
          it "should return all users with staffer role in any mission" do
            expect(subject).to contain_exactly(first_user, third_user)
          end
        end
      end
    end
  end
end
