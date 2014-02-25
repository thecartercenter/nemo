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


  test "#determine_mission will return the passed in mission" do
    q = FactoryGirl.build(:question, :code => 'Alpha')
    assert('some_mission', q.determine_mission({:mission => "some_mission"}))
  end

  test "#determine_mission will return nil if the mode is :promote" do
    q = FactoryGirl.build(:question, :code => 'Alpha')
    assert_nil(q.determine_mission({:mode => :promote, :mission => "doesn't matter"}))
  end

  test "#determine_mission will return nil if a mission is not specified" do
    q = FactoryGirl.build(:question, :code => 'Alpha')
    assert_nil(q.determine_mission({:mode => :default}))
  end

  test "#determine_mission will return the passed in parameter if it is not a hash" do
    q = FactoryGirl.build(:question, :code => 'Alpha')
    assert("some_mission", q.determine_mission("some_mission"))
  end

end
