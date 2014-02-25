require 'test_helper'

# tests for standardizable functionality as applied to options
class StandardizableOptionTest < ActiveSupport::TestCase

  test "copy_for_mission should return the correct object" do
    o = FactoryGirl.create(:option, :is_standard => true)
    o2 = o.replicate(:mode => :to_mission, :mission => get_mission)
    assert_equal(o2, o.copy_for_mission(get_mission))
    assert_nil(o.copy_for_mission(nil))
    assert_nil(o.copy_for_mission(FactoryGirl.create(:mission, :name => 'junk')))
  end

  test "replicating non-standard-linked object within mission should work" do
    o = FactoryGirl.build(:option, :name => 'Stuff')
    o2 = o.replicate(:mode => :clone)
    assert(!o.is_standard, 'original should not be standard')
    assert(!o2.is_standard, 'copy should not be standard')
    assert_nil(o.standard_id)
    assert_nil(o2.standard_id)
    assert_not_nil(o.mission)
    assert_equal(o.mission, o2.mission)
    assert_equal(o.name, o2.name)
    assert_not_equal(o.id, o2.id)
    assert(!o2.new_record?, 'new option should be saved')
  end

  test "replicating standard-linked object within mission should not retain standard link" do
    so = FactoryGirl.build(:option, :name => 'Stuff', :is_standard => true)
    o = FactoryGirl.build(:option, :name => 'Stuff', :standard => so)

    # standard objects should have nil mission
    assert_nil(so.mission)
    assert_not_nil(o.mission)

    # copy should not have standard link
    o2 = o.replicate(:mode => :clone)
    assert_nil(o2.standard)
    assert_equal(o.mission, o2.mission)
  end

  test "replicating standard option should work" do
    o = FactoryGirl.build(:option, :name => 'Stuff', :is_standard => true)
    o2 = o.replicate(:mode => :to_mission, :mission => get_mission)

    # copy should have correct mision
    assert_equal(get_mission, o2.mission)

    # copy should not be standard but should retain link to standard
    assert(!o2.is_standard?, "copy should not be standard")
    assert_equal(o, o2.standard)
    assert_equal(o.id, o2.standard_id)
  end

  test "standard and copies associations should work without reload" do
    o = FactoryGirl.build(:option, :name => 'Stuff', :is_standard => true)
    o2 = o.replicate(:mode => :to_mission, :mission => get_mission)

    # o.copies associate should work even before reload
    assert_equal(o2.standard, o)
    assert_equal(o.copies, [o2])
  end

  test "update of user-modifiable param in a std option should not replicate to copy if copy changed" do
    o = FactoryGirl.create(:option, :name => 'Stuff', :is_standard => true)
    o2 = o.replicate(:mode => :to_mission, :mission => get_mission)

    # change copy first
    o2.name = 'Blah'
    o2.save!

    # do update
    o.reload.name = 'Stuffz'
    o.save!

    # check non-replication
    assert_equal('Blah', o2.reload.name)
  end

  test "deleting std option should delete copies" do
    o = FactoryGirl.create(:option, :name => 'Stuff', :is_standard => true)
    o2 = o.replicate(:mode => :to_mission, :mission => get_mission)
    o.destroy
    assert_nil(Option.where(:id => o2.id).first)
  end

end
