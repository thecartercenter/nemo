require 'test_helper'

class QuestionTest < ActiveSupport::TestCase

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

  test "not in form" do
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
    q = FactoryGirl.create(:question, :qtype_name => 'integer', :code => 'intq')
    assert_nil(q.options)
  end

  test "integer question should have non-null minstrictly value if minimum is set" do
    q = FactoryGirl.create(:question, :qtype_name => 'integer', :minimum => 4, :minstrictly => nil)
    assert_equal(false, q.minstrictly)
    q = FactoryGirl.create(:question, :qtype_name => 'integer', :minimum => 4, :minstrictly => false)
    assert_equal(false, q.minstrictly)
    q = FactoryGirl.create(:question, :qtype_name => 'integer', :minimum => 4, :minstrictly => true)
    assert_equal(true, q.minstrictly)
  end

  test "integer question should have null minstrictly value if minimum is null" do
    q = FactoryGirl.create(:question, :qtype_name => 'integer', :minimum => nil, :minstrictly => true)
    assert_nil(q.minstrictly)
    q = FactoryGirl.create(:question, :qtype_name => 'integer', :minimum => nil, :minstrictly => false)
    assert_nil(q.minstrictly)
  end

  test "non numeric questions should have null constraint values" do
    q = FactoryGirl.create(:question, :qtype_name => 'text', :minimum => 5, :minstrictly => true)
    assert_nil(q.minimum)
    assert_nil(q.minstrictly)
  end
end
