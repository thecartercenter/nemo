require 'test_helper'

# tests the functions in the Replicable mixin
class ReplicableTest < ActiveSupport::TestCase

  test "attrib_before_save should work for changed attribs" do
    q = FactoryGirl.create(:question, :code => 'Alpha')
    q.code = 'Bravo'
    q.save!
    assert_equal('Alpha', q.attrib_before_save(:code))
  end

  test "attrib_before_save should work for unchanged attribs on update" do
    q = FactoryGirl.create(:question, :code => 'Alpha')

    # change some other attribute
    q.minimum = 5
    q.save!

    # code should not be in previous_changes but the method should work anyway
    assert(!q.previous_changes.has_key?('code'))
    assert_equal('Alpha', q.attrib_before_save(:code))
  end

  test "attrib_before_save should return initial value on create" do
    q = FactoryGirl.create(:question, :code => 'Alpha')
    assert_equal('Alpha', q.attrib_before_save(:code))
  end

end
