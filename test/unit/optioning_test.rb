require 'test_helper'

class OptioningTest < ActiveSupport::TestCase

  test "must have parent if option level is not rank 1" do
    o = Optioning.new
    o.stubs(:option_level).returns(stub(:rank => 2))
    o.send(:must_have_parent_if_not_top_option_level)
    assert_match(/can't be blank/, o.errors[:parent_id].join)
  end

  test "can have nil parent if option level is nil or rank 1" do
    o = Optioning.new
    o.send(:must_have_parent_if_not_top_option_level)
    assert_equal('', o.errors[:parent_id].join)

    o = Optioning.new
    o.stubs(:option_level).returns(stub(:rank => 1))
    o.send(:must_have_parent_if_not_top_option_level)
    assert_equal('', o.errors[:parent_id].join)
  end

  test "must have option level if option set is multi_level true" do
    o = Optioning.new
    o.stubs(:option_set).returns(stub(:multi_level? => true))
    o.send(:must_have_option_level_if_in_multi_level_option_set)
    assert_match(/can't be blank if/, o.errors[:option_level_id].join)
  end
end