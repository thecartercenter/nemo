require 'rails_helper'

describe 'user form' do
  context 'as admin' do
    before do
      @self = create(:user, :admin => true)
    end

    context 'when editing self' do
      before do
        login(@self)
      end

      context 'in basic mode' do
        before do
          get_s edit_user_path(@self, :mode => nil, :mission_name => nil)
        end

        # These two role field tests make sure the change_assignments ability is protecting the role field.
        # They do not test all possible combinations of mode and role.
        # For detailed tests of user abilities, see models/ability/user_spec.
        it 'should not show role field' do
          assert_select('div.user_role', false)
        end
      end

      context 'in mission mode' do
        before do
          get_s(edit_user_path(@self, :mode => 'm', :mission_name => get_mission.compact_name))
        end

        it 'should show role field' do
          assert_select('div.user_role', true)
        end
      end
    end
  end
end