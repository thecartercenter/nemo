require 'test_helper'

class OptionTest < ActiveSupport::TestCase

  test "create" do
    FactoryGirl.create(:option, :name => 'Foo')
    # no raise means saved properly
  end
  
  test "name lengths can't be too long" do
    o = FactoryGirl.build(:option, :name => 'Foooooooooo oooo oooooooooooo oooooooooooooooo')
    o.save
    assert_match(/characters in length/, o.errors.messages[:base].join)
  end
  
  test "names can't all be blank" do
    o = FactoryGirl.build(:option, :name => '')
    o.save
    assert_match(/At least one name translation/, o.errors.messages[:base].join)
  end

  test "replicate non-standard non-standard-linked object within mission should work" do
    o = FactoryGirl.build(:option, :name => 'Stuff')
    o2 = o.replicate
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

  test "replicate standard-linked object within mission should not retain standard link" do
    so = FactoryGirl.build(:option, :name => 'Stuff', :is_standard => true)
    o = FactoryGirl.build(:option, :name => 'Stuff', :standard => so)
    
    # standard objects should have nil mission
    assert_nil(so.mission)
    assert_not_nil(o.mission)

    # copy should not have standard link
    o2 = o.replicate
    assert_nil(o2.standard)
    assert_equal(o.mission, o2.mission)
  end

  test "replicate standard option should work" do
    o = FactoryGirl.build(:option, :name => 'Stuff', :is_standard => true)
    o2 = o.replicate(get_mission)

    # copy should have correct mision
    assert_equal(get_mission, o2.mission)

    # copy should not be standard but should retain link to standard
    assert(!o2.is_standard?, "copy should not be standard")
    assert_equal(o, o2.standard)
    assert_equal(o.id, o2.standard_id)
  end
end