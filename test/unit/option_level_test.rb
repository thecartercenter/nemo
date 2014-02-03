require 'test_helper'

class OptionLevelTest < ActiveSupport::TestCase

  test "factory should work" do
    ol = FactoryGirl.build(:option_level)
    ol.save!
  end

  test "name translations should not be allowed to be all blank" do
    ol = FactoryGirl.build(:option_level, :name_translations => nil)
    assert_equal(false, ol.valid?)
  end
end
