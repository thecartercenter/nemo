# frozen_string_literal: true

# Tests for abilities related to User object.
# Only tests admins vs. regular users (coordinators) currently.
# This distinction seems to be the trickiest.
# Observer and staffer abilities are not currently tested.
require "rails_helper"

describe "abilities for users" do
  shared_examples_for "admin abilities in mission mode" do
    before(:all) do
      @ability = Ability.new(user: @user, mode: "mission", mission: get_mission)
    end

    it "should allow edit profile" do
      expect(@ability).to be_able_to(:update, @user)
    end

    it "should not allow adminify self" do
      expect(@ability).not_to be_able_to(:adminify, @user)
    end

    it "should allow adminify others" do
      expect(@ability).to be_able_to(:adminify, @user2)
    end

    it "should allow changing own assignments" do
      expect(@ability).to be_able_to(:change_assignments, @user)
    end
  end

  shared_examples_for "admin or coordinator shared abilities" do
    context "in basic mode" do
      before(:all) do
        @ability = Ability.new(user: @user, mode: "basic")
      end

      it "should not allow index or create" do
        expect(@ability).not_to be_able_to(:index, User)
        expect(@ability).not_to be_able_to(:create, User)
      end

      context "for self" do
        it "should allow show and edit" do
          expect(@ability).to be_able_to(:show, @user)
          expect(@ability).to be_able_to(:update, @user)
        end

        it "should disallow other actions" do
          expect(@ability).not_to be_able_to(:adminify, @user)
          expect(@ability).not_to be_able_to(:change_assignments, @user)
          expect(@ability).not_to be_able_to(:activate, @user)
        end
      end

      context "for other user" do
        it "should allow nothing" do
          expect(@ability).not_to be_able_to(:index, @user2)
          expect(@ability).not_to be_able_to(:create, @user2)
          expect(@ability).not_to be_able_to(:show, @user2)
          expect(@ability).not_to be_able_to(:update, @user2)
          expect(@ability).not_to be_able_to(:change_assignments, @user2)
          expect(@ability).not_to be_able_to(:activate, @user2)
        end
      end
    end

    context "in mission mode" do
      before(:all) do
        @ability = Ability.new(user: @user, mode: "mission", mission: get_mission)
      end

      it "should allow index and create" do
        expect(@ability).to be_able_to(:index, User)
        expect(@ability).to be_able_to(:create, User)
      end

      context "for self" do
        it "should allow show and edit" do
          expect(@ability).to be_able_to(:show, @user)
          expect(@ability).to be_able_to(:update, @user)
        end

        it "should disallow other actions" do
          expect(@ability).not_to be_able_to(:adminify, @user)
          expect(@ability).not_to be_able_to(:activate, @user)
        end
      end

      context "for other user" do
        it "should allow show, edit, activate, and chg assign" do
          expect(@ability).to be_able_to(:show, @user2)
          expect(@ability).to be_able_to(:update, @user2)
          expect(@ability).to be_able_to(:activate, @user2)

          # The form restricts this to the current mission's role only.
          expect(@ability).to be_able_to(:change_assignments, @user2)
        end
      end
    end
  end

  context "for a coordinator" do
    before(:all) do
      @user = create(:user, name: "self", role_name: "coordinator")
      @user2 = create(:user, name: "other")
    end

    it_behaves_like "admin or coordinator shared abilities"

    context "in mission mode" do
      before(:all) do
        @ability = Ability.new(user: @user, mode: "mission", mission: get_mission)
      end

      it "should not allow adminify self or others" do
        expect(@ability).not_to be_able_to(:adminify, @user)
        expect(@ability).not_to be_able_to(:adminify, @user2)
      end

      it "should not allow changing own assignments" do
        expect(@ability).not_to be_able_to(:change_assignments, @user)
      end
    end
  end

  context "for an admin user" do
    before(:all) do
      @user = create(:user, admin: true)
      @user2 = create(:user, name: "other")
    end

    it_behaves_like "admin or coordinator shared abilities"

    context "in mission mode" do
      context "when assigned to mission" do
        it_behaves_like "admin abilities in mission mode"
      end

      context "when not assigned to mission" do
        before { @user.assignments.destroy_all }
        it_behaves_like "admin abilities in mission mode"
      end
    end

    # None of these are covered in admin/coord shared abilities since only admins
    # can be in admin mode.
    context "in admin mode" do
      before(:all) do
        @ability = Ability.new(user: @user, mode: "admin")
      end

      it "should allow index and create" do
        expect(@ability).to be_able_to(:index, User)
        expect(@ability).to be_able_to(:create, User)
      end

      context "for self" do
        it "should allow show, edit, and chg assignments" do
          expect(@ability).to be_able_to(:show, @user)
          expect(@ability).to be_able_to(:update, @user)
          expect(@ability).to be_able_to(:change_assignments, @user)
        end

        it "should disallow other actions" do
          expect(@ability).not_to be_able_to(:adminify, @user)
          expect(@ability).not_to be_able_to(:activate, @user)
        end
      end

      context "for other user" do
        it "should allow all actions" do
          expect(@ability).to be_able_to(:show, @user2)
          expect(@ability).to be_able_to(:update, @user2)
          expect(@ability).to be_able_to(:change_assignments, @user2)
          expect(@ability).to be_able_to(:adminify, @user2)
          expect(@ability).to be_able_to(:activate, @user2)
        end
      end
    end
  end
end
