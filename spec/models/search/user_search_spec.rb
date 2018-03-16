# tests the search functionality for the user model
require "spec_helper"

describe User do
  describe "search" do
    let!(:first_group) { create(:user_group) }
    let!(:second_group) { create(:user_group) }
    let!(:first_user) { create(:user_group_assignment, user_group: first_group).user }
    let!(:second_user) { create(:user_group_assignment, user_group: first_group).user }
    let!(:third_user) { create(:user_group_assignment, user_group: second_group).user }

    subject { User.do_search(User, query).to_a }

    context "searching by group" do
      let(:query) {%[group:"#{group_sought.name}"]}

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
      let(:query) {%[role:"#{role_sought}"]}
      let(:other_mission) {create(:mission)}

      before(:each) do
        first_user.assignments.create!(mission: get_mission, role: "enumerator")
        first_user.assignments.create!(mission: other_mission, role: "staffer")
        second_user.assignments.create!(mission: get_mission, role: "coordinator")
        third_user.assignments.create!(mission: get_mission, role: "staffer")
      end

      context "in mission" do

        context "searching for staffer" do
          let(:role_sought) {"staffer"}

          it "should return only user with staffer role in current mission" do
            expect(subject).to contain_exactly(third_user)
          end
        end

        context "searching for staffer" do
          let(:role_sought) {"enumerator"}

          it "should return only user with enumerator role in current mission" do
            expect(subject).to contain_exactly(first_user)
          end
        end
      end
      context "admin mode" do
        context "searching for staffer" do
          let(:role_sought) {"staffer"}

          it "should return only user with staffer role in current mission" do
            expect(subject).to contain_exactly(first_user, third_user)
          end
        end
      end
    end
  end
end
