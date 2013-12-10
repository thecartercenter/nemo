require 'test_helper'

class UserTest < ActiveSupport::TestCase
  
  setup do
    @mission = get_mission
    @mission.setting.load
  end
  
  test "creating a user with minimal info should produce good defaults" do
    user = User.create!(:name => 'Alpha Tester', :reset_password_method => 'print', 
      :assignments => [Assignment.new(:mission => @mission, :role => User::ROLES.first, :active => true)])
    assert_equal('en', user.pref_lang)
    assert_equal('atester', user.login)
  end
  
  test "phone numbers should be unique" do
    # create a user with two phone numbers
    first = FactoryGirl.create(:user, :phone => "+19998887777", :phone2 => "+17776665537")
    
    # try to create a user with phone = first.phone; should fail
    assert_phone_uniqueness_error(FactoryGirl.build(:user, :login => "foo", :phone => "+19998887777"))
    
    # try to create a user with phone = first.phone2; should fail
    assert_phone_uniqueness_error(FactoryGirl.build(:user, :login => "foo", :phone2 => "+19998887777"))

    # try to create a user with phone2 = first.phone; should fail
    assert_phone_uniqueness_error(FactoryGirl.build(:user, :login => "foo", :phone => "+17776665537"))

    # try to create a user with phone2 = first.phone2; should fail
    assert_phone_uniqueness_error(FactoryGirl.build(:user, :login => "foo", :phone2 => "+17776665537"))
    
    # try to create a user with no phone numbers; shouldn't fail
    second = FactoryGirl.build(:user, :login => "foo")
    second.save!
    
    # try to edit this new user to conflicting phone number, should fail
    second.assign_attributes(:phone => "+19998887777")
    assert_phone_uniqueness_error(second)
    
    # create a user with different phone numbers and make sure no error
    third = FactoryGirl.build(:user, :login => "bar", :phone => "+19998887770", :phone2 => "+17776665530")
    third.save!
  end
  
  private
    # attempts to save user and expects to get a phone uniqueness error
    def assert_phone_uniqueness_error(user)
      begin
        user.save!
      rescue ActiveRecord::RecordInvalid
        assert_match(/phone.+assigned/i, $!.to_s)
      else
        fail("Validation error should have been raised")
      end
    end
end