require 'test_helper'

class OptioningTest < ActiveSupport::TestCase

  test "must have parent if option level is not rank 1" do
    o = Optioning.new
    o.stubs(:option_level).returns(stub(:rank => 2))
    o.valid?
    assert_match(/can't be blank/, o.errors[:parent_id].join)
  end

  test "can have nil parent if option level is nil or rank 1" do
    o = Optioning.new
    assert_equal(true, o.valid?)

    o = Optioning.new
    o.stubs(:option_level).returns(stub(:rank => 1))
    assert_equal(true, o.valid?)
  end
end