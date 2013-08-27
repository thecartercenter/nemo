require 'test_helper'

class QuestionTest < ActiveSupport::TestCase

  setup do
    clear_objects(Question)
  end

  test "creation" do
    FactoryGirl.create(:question)
    # should not raise
  end
  
  test "code must be correct format" do
    q = FactoryGirl.build(:question, :code => 'a b')
    q.save
    assert_match(/Code is invalid/, q.errors.full_messages.join)
    
    # but dont raise this error if not present (let the presence validator handle that)
    q = FactoryGirl.build(:question, :code => '')
    q.save
    assert_not_match(/Code is invalid/, q.errors.full_messages.join)
  end
  
  # this also tests .qtype and .has_options (delegated)
  test "select questions must have option set" do
    q = FactoryGirl.build(:question, :qtype_name => 'select_one')
    q.option_set = nil
    q.save
    assert_match(/Option set can't be blank/, q.errors.full_messages.join)
  end
  
  test "not in proto form" do
    f = FactoryGirl.create(:form, :question_types => %w(integer integer))
    q = FactoryGirl.create(:question)
    assert_equal([q], Question.not_in_form(f).all)
  end
  
  test "min max error message" do
    q = FactoryGirl.build(:question, :qtype_name => 'integer', :minimum => 10, :maximum => 20, :minstrictly => false, :maxstrictly => true)
    assert_equal('must be greater than or equal to 10 and less than 20', q.min_max_error_msg)
  end
  
  test "options" do
    q = FactoryGirl.create(:question, :qtype_name => 'select_one')
    q.reload
    assert_equal(%w(Yes No), q.options.map(&:name))
    q = FactoryGirl.create(:question, :qtype_name => 'integer')
    assert_nil(q.options)
  end

  test "replicating a question within a mission should change the code" do
    q = FactoryGirl.create(:question, :qtype_name => 'integer', :code => 'Foo')
    q2 = q.replicate
    assert_equal('FooCopy', q2.code)
    q3 = q2.replicate
    assert_equal('FooCopy2', q3.code)
    q4 = q3.replicate
    assert_equal('FooCopy3', q4.code)
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
    assert_not_nil(q2.option_set.mission)
  end
end
