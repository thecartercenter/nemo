require 'test_helper'

class StandardizableTest < ActiveSupport::TestCase

  test "copy_for_mission" do
    o = FactoryGirl.create(:option, :is_standard => true)
    o2 = o.replicate(get_mission)
    assert_equal(o2, o.copy_for_mission(get_mission))
    assert_nil(o.copy_for_mission(nil))
    assert_nil(o.copy_for_mission(FactoryGirl.create(:mission, :name => 'junk')))
  end
  
end
