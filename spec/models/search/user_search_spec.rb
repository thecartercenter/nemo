# tests the search functionality for the user model
require "spec_helper"

describe User do
  describe "search" do
    let!(:first_group) { create(:user_group) }
    let!(:second_group) { create(:user_group) }
    let!(:first_user) { create(:user_group_assignment, user_group: first_group).user }
    let!(:second_user) { create(:user_group_assignment, user_group: first_group).user }
    let!(:third_user) { create(:user_group_assignment, user_group: second_group).user }

    context "searching by group" do
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

    context "searching by role" do
      let!(:fourth_user) { create(:user, role_name: "coordinator") }


      subject { User.with_roles(get_mission, %w[enumerator reviewer staffer coordinator]).do_search(User.with_roles(get_mission, %w[enumerator reviewer staffer coordinator]), %[role:"staffer"]).to_a }

      before(:each) do
        first_user.assignments.create!(mission: get_mission, role: "enumerator")
        second_user.assignments.create!(mission: get_mission, role: "coordinator")
        third_user.assignments.create!(mission: get_mission, role: "staffer")
      end

      it "should return admins with staffer role" do
        expect(subject).to contain_exactly(third_user)
      end

      it "should return coordinators with coordinator role" do

      end

      it "should return observers with observer role" do

      end

      #TODO: Admin? should admin be a separate search term? like is_admin: t/f?
    end
  end
end
