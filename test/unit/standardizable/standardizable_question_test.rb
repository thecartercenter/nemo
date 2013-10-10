require 'test_helper'

# tests for standardizable functionality as applied to questions
class StandardizableQuestionTest < ActiveSupport::TestCase

  test "replicating a question within a mission should change the code" do
    q = FactoryGirl.create(:question, :qtype_name => 'integer', :code => 'Foo')
    q2 = q.replicate
    assert_equal('Foo2', q2.code)
    q3 = q2.replicate
    assert_equal('Foo3', q3.code)
    q4 = q3.replicate
    assert_equal('Foo4', q4.code)
  end

  test "replicating a standard question should not change the code" do
    q = FactoryGirl.create(:question, :qtype_name => 'integer', :code => 'Foo', :is_standard => true)
    q2 = q.replicate(get_mission)
    assert_equal(q.code, q2.code)
    q = FactoryGirl.create(:question, :qtype_name => 'integer', :code => 'Foo1', :is_standard => true)
    q2 = q.replicate(get_mission)
    assert_equal(q.code, q2.code)
  end

  test "replicating a question should not replicate the key field" do
    q = FactoryGirl.create(:question, :qtype_name => 'integer', :key => true)
    q2 = q.replicate

    assert_not_equal(q, q2)
    assert_not_equal(q.key, q2.key)
  end

  test "replicating a select question within a mission should not replicate the option set" do
    q = FactoryGirl.create(:question, :qtype_name => 'select_one')
    q2 = q.replicate
    assert_not_equal(q, q2)
    assert_equal(q.option_set, q2.option_set)
  end

  test "replicating a standard select question should replicate the option set" do
    q = FactoryGirl.create(:question, :qtype_name => 'select_one', :is_standard => true)

    # ensure the std q looks right
    assert_nil(q.mission)
    assert_nil(q.option_set.mission)
    assert(q.option_set.is_standard)

    # replicate and test
    q2 = q.replicate(get_mission)
    assert_not_equal(q, q2)
    assert_not_equal(q.option_set, q2.option_set)
    assert_not_equal(q.option_set.options.first, q2.option_set.options.first)
    assert_not_nil(q2.option_set.mission)
  end

  test "replicating question with short code that ends in zero should work" do
    q = FactoryGirl.create(:question, :qtype_name => 'integer', :code => 'q0')
    q2 = q.replicate
    assert_equal('q1', q2.code)
  end

  test "name should be replicated on create" do
    q = FactoryGirl.create(:question, :is_standard => true, :name => 'Foo')
    q2 = q.replicate(get_mission)
    assert_equal('Foo', q2.name)

    # also test _name attrib
    assert_equal('Foo', q2._name)
  end

  test "name should be replicated on update if copy hasnt changed" do
    q = FactoryGirl.create(:question, :is_standard => true, :name => 'Foo')
    q2 = q.replicate(get_mission)
    q.name = 'Bar'
    q.save!
    assert_equal('Bar', q2.reload.name)

    # also test _name attrib
    assert_equal('Bar', q2._name)
  end

  test "name should not be replicated on update if copy has changed" do
    other_mission = FactoryGirl.create(:mission, :name => 'other')
    q = FactoryGirl.create(:question, :is_standard => true, :name => 'Foo')
    copy1 = q.replicate(get_mission)
    copy2 = q.replicate(other_mission)

    # change copy1
    copy1.name = 'Baz'
    copy1.save!

    # now change std -- change should not replicate to copy1
    q.reload.name = 'Bar'
    q.save!
    assert_equal('Baz', copy1.reload.name)
    assert_equal('Bar', copy2.reload.name)

    # also test _name attrib
    assert_equal('Baz', copy1.reload._name)
    assert_equal('Bar', copy2.reload._name)
  end
end