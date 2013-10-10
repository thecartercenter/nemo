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

  test "suggestions should work for nil mission" do
    # create dummy standard option
    o = FactoryGirl.create(:option, :is_standard => true, :name => 'Foo')

    # ask for suggestions
    s = Option.suggestions(nil, 'f')

    # should be two suggestions: Foo, and the new option one
    assert_equal(2, s.size)
    assert(s.any?{|o| o[:name] == 'Foo'})
  end
end