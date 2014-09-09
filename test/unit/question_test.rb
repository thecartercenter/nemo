require 'test_helper'

class QuestionTest < ActiveSupport::TestCase

  test "creation" do
    FactoryGirl.create(:question)
    # should not raise
  end

  test "code must be correct format" do
    q = FactoryGirl.build(:question, :code => 'a b')
    q.save
    assert_match(/Code: Should start with a letter/, q.errors.full_messages.join)

    # but dont raise this error if not present (let the presence validator handle that)
    q = FactoryGirl.build(:question, :code => '')
    q.save
    assert_not_match(/Code: Should start with a letter/, q.errors.full_messages.join)
  end

  # this also tests .qtype and .has_options (delegated)
  test "select questions must have option set" do
    q = FactoryGirl.build(:question, :qtype_name => 'select_one')
    q.option_set = nil
    q.save
    assert_match(/is required/, q.errors[:option_set].join)
  end

  test "not in form" do
    f = FactoryGirl.create(:form, :question_types => %w(integer integer))
    q = FactoryGirl.create(:question)
    assert_equal([q], Question.not_in_form(f).all)
  end

  test "min max error message" do
    q = FactoryGirl.build(:question, :qtype_name => 'integer', :minimum => 10, :maximum => 20, :minstrictly => false, :maxstrictly => true)
    assert_equal('Must be greater than or equal to 10 and less than 20', q.min_max_error_msg)
  end

  test "options" do
    q = FactoryGirl.create(:question, :qtype_name => 'select_one')
    q.reload
    assert_equal(%w(Cat Dog), q.options.map(&:name))
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

  test "promoting a question with an option set should work" do
    q = FactoryGirl.create(:question, :qtype_name => 'select_one', :option_set => FactoryGirl.create(:option_set))
    std = q.replicate(:mode => :promote)

    # mission should now be nil and should be standard
    assert_equal(true, std.is_standard)
    assert_equal(nil, std.mission)

    # all objects should be distinct
    assert_not_equal(q, std)
    assert_not_equal(q.option_set, std.option_set)

    # all std objects should be standard
    assert_equal(true, std.is_standard?)
    assert_equal(true, std.option_set.is_standard?)

    # originals should not have standard links
    assert_nil(q.standard)
    assert_nil(q.option_set.standard)
  end

  test "promoting a question and maintaining link should work" do
    q = FactoryGirl.create(:question, :qtype_name => 'select_one', :option_set => FactoryGirl.create(:option_set))
    std = q.replicate(:mode => :promote, :retain_link_on_promote => true)
    q.reload

    # all std objects should be standard
    assert_equal(true, std.is_standard?)
    assert_equal(true, std.option_set.is_standard?)

    # originals should have standard links
    assert_equal(std, q.standard)
    assert_equal(std.option_set, q.option_set.standard)
  end
end
