require 'test_helper'

class AbilityTest < ActiveSupport::TestCase

	test 'coordinators should be able to create users for their current mission' do
		coord = FactoryGirl.create(:user, :role_name => 'coordinator')
		coord.set_current_mission
		a = Ability.new(coord)

		u = User.new
		assert(a.cannot?(:create, u))
		u.assignments.build(:mission => coord.current_mission)
		assert(a.can?(:create, u))
	end

	test 'staffers should not be able to create users' do
		staffer = FactoryGirl.create(:user, :role_name => 'staffer')
		staffer.set_current_mission
		a = Ability.new(staffer)

		u = User.new
		assert(a.cannot?(:create, u))
		u.assignments.build(:mission => staffer.current_mission)
		assert(a.cannot?(:create, u))
	end
end
