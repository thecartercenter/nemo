require 'test_helper'

# tests the functions in the Replicable mixin
class ReplicableTest < ActiveSupport::TestCase

  test "attrib_before_save should work for changed attribs" do
    q = FactoryGirl.create(:question, :code => 'Alpha')
    q.code = 'Bravo'
    q.save!
    assert_equal('Alpha', q.attrib_before_save(:code))
  end

end