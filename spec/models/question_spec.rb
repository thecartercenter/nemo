require 'spec_helper'

describe Question do

  it "creation" do
    create(:question) # should not raise
  end

  it "code must be correct format" do
    q = build(:question, code: 'a b')
    q.save
    assert_match(/Code: Should start with a letter/, q.errors.full_messages.join)

    # but dont raise this error if not present (let the presence validator handle that)
    q = build(:question, code: '')
    q.save
    expect(q.errors.full_messages.join).not_to match(/Code: Should start with a letter/)
  end

  # this also tests .qtype and .has_options (delegated)
  it "select questions must have option set" do
    q = build(:question, qtype_name: 'select_one')
    q.option_set = nil
    q.save
    assert_match(/is required/, q.errors[:option_set].join)
  end

  it "not in form" do
    f = create(:form, question_types: %w(integer integer))
    q = create(:question)
    assert_equal([q], Question.not_in_form(f).all)
  end

  it "min max error message" do
    q = build(:question, qtype_name: 'integer', minimum: 10, maximum: 20, minstrictly: false, maxstrictly: true)
    assert_equal('Must be greater than or equal to 10 and less than 20', q.min_max_error_msg)
  end

  it "options" do
    q = create(:question, qtype_name: 'select_one')
    q.reload
    assert_equal(%w(Cat Dog), q.options.map(&:name))
    q = create(:question, qtype_name: 'integer', code: 'intq')
    assert_nil(q.options)
  end

  it "integer question should have non-null minstrictly value if minimum is set" do
    q = create(:question, qtype_name: 'integer', minimum: 4, minstrictly: nil)
    assert_equal(false, q.minstrictly)
    q = create(:question, qtype_name: 'integer', minimum: 4, minstrictly: false)
    assert_equal(false, q.minstrictly)
    q = create(:question, qtype_name: 'integer', minimum: 4, minstrictly: true)
    assert_equal(true, q.minstrictly)
  end

  it "integer question should have null minstrictly value if minimum is null" do
    q = create(:question, qtype_name: 'integer', minimum: nil, minstrictly: true)
    assert_nil(q.minstrictly)
    q = create(:question, qtype_name: 'integer', minimum: nil, minstrictly: false)
    assert_nil(q.minstrictly)
  end

  it "non numeric questions should have null constraint values" do
    q = create(:question, qtype_name: 'text', minimum: 5, minstrictly: true)
    assert_nil(q.minimum)
    assert_nil(q.minstrictly)
  end
end
