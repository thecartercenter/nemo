# Tests for abilities related to User object.
# Only tests admins vs. regular users (coordinators) currently.
# This distinction seems to be the trickiest.
# Observer and staffer abilities are not currently tested.
require 'spec_helper'

describe 'abilities for users' do

  #######################################
  # These are common abilities that are the same for admins and coordinators.
  shared_examples_for 'admin or coordinator' do

    context 'in basic mode' do
      before(:all) do
        @mode = 'basic'
        @mission = nil
      end

      it 'should not allow index or create' do
        @target = User
        expect_not_able_to(:index)
        expect_not_able_to(:create)
      end

      context 'for self' do
        before(:all) do
          @target = @user
        end

        it 'should allow show and edit' do
          expect_able_to(:show)
          expect_able_to(:update)
        end

        it 'should disallow other actions' do
          expect_not_able_to(:adminify)
          expect_not_able_to(:change_assignments)
        end
      end

      context 'for other user' do
        before(:all) do
          @target = @user2
        end

        it 'should allow nothing' do
          expect_not_able_to(:index)
          expect_not_able_to(:create)
          expect_not_able_to(:show)
          expect_not_able_to(:update)
          expect_not_able_to(:change_assignments)
        end
      end
    end

    context 'in mission mode' do
      before(:all) do
        @mode = 'mission'
        @mission = get_mission
      end

      it 'should allow index and create' do
        @target = User
        expect_able_to(:index)
        expect_able_to(:create)
      end

      context 'for self' do
        before(:all) do
          @target = @user
        end

        it 'should allow show and edit' do
          expect_able_to(:show)
          expect_able_to(:update)
        end

        it 'should disallow other actions' do
          expect_not_able_to(:adminify)
        end
      end

      context 'for other user' do
        before(:all) do
          @target = @user2
        end

        it 'should allow show, edit, and chg assign' do
          expect_able_to(:show)
          expect_able_to(:update)

          # The form restricts this to the current mission's role only.
          expect_able_to(:change_assignments)
        end
      end
    end
  end
  ##############################################################

  context 'for a coordinator' do
    before(:all) do
      @user = create(:user, :name => 'self', :role_name => 'coordinator')
      @user2 = create(:user, :name => 'other')
    end

    it_behaves_like 'admin or coordinator'

    context 'in mission mode' do
      before(:all) do
        @mode = 'mission'
        @mission = get_mission
      end

      it 'should not allow adminify self or others' do
        @target = @user; expect_not_able_to(:adminify)
        @target = @user2; expect_not_able_to(:adminify)
      end

      it 'should not allow changing own assignments' do
        @target = @user
        expect_not_able_to(:change_assignments)
      end
    end
  end

  context 'for an admin user' do

    before(:all) do
      @user = create(:user, :admin => true)
      @user2 = create(:user, :name => 'other')
    end

    it_behaves_like 'admin or coordinator'

    context 'in mission mode' do
      before(:all) do
        @mode = 'mission'
        @mission = get_mission
      end

      it 'should not allow adminify self' do
        @target = @user
        expect_not_able_to(:adminify)
      end

      it 'should allow adminify others' do
        @target = @user2
        expect_able_to(:adminify)
      end

      it 'should allow changing own assignments' do
        @target = @user
        expect_able_to(:change_assignments)
      end
    end

    context 'in admin mode' do
      before(:all) do
        @mode = 'admin'
        @mission = nil
      end

      it 'should allow index and create' do
        @target = User
        expect_able_to(:index)
        expect_able_to(:create)
      end

      context 'for self' do
        before(:all) do
          @target = @user
        end

        it 'should allow show, edit, and chg assignments' do
          expect_able_to(:show)
          expect_able_to(:update)
          expect_able_to(:change_assignments)
        end

        it 'should disallow other actions' do
          expect_not_able_to(:adminify)
        end
      end

      context 'for other user' do
        before(:all) do
          @target = @user2
        end

        it 'should allow all actions' do
          expect_able_to(:show)
          expect_able_to(:update)
          expect_able_to(:change_assignments)
          expect_able_to(:adminify)
        end
      end
    end

  end

  def ability
    Ability.new(:user => @user, :mode => @mode, :mission => @mission)
  end

  def expect_able_to(action)
    expect(ability.can?(action, @target)).to be_truthy
  end

  def expect_not_able_to(action)
    expect(ability.cannot?(action, @target)).to be_truthy
  end
end
