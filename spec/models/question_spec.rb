require 'spec_helper'

describe Question do
  it_behaves_like "has a uuid"

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
    expect(Question.not_in_form(f).all).to eq([q])
  end

  it "min max error message" do
    q = build(:question, qtype_name: 'integer', minimum: 10, maximum: 20, minstrictly: false, maxstrictly: true)
    expect(q.min_max_error_msg).to eq('Must be greater than or equal to 10 and less than 20')
  end

  it "options" do
    q = create(:question, qtype_name: 'select_one')
    q.reload
    expect(q.options.map(&:name)).to eq(%w(Cat Dog))
    q = create(:question, qtype_name: 'integer', code: 'intq')
    expect(q.options).to be_nil
  end

  it "integer question should have non-null minstrictly value if minimum is set" do
    q = create(:question, qtype_name: 'integer', minimum: 4, minstrictly: nil)
    expect(q.minstrictly).to eq(false)
    q = create(:question, qtype_name: 'integer', minimum: 4, minstrictly: false)
    expect(q.minstrictly).to eq(false)
    q = create(:question, qtype_name: 'integer', minimum: 4, minstrictly: true)
    expect(q.minstrictly).to eq(true)
  end

  it "integer question should have null minstrictly value if minimum is null" do
    q = create(:question, qtype_name: 'integer', minimum: nil, minstrictly: true)
    expect(q.minstrictly).to be_nil
    q = create(:question, qtype_name: 'integer', minimum: nil, minstrictly: false)
    expect(q.minstrictly).to be_nil
  end

  it "non numeric questions should have null constraint values" do
    q = create(:question, qtype_name: 'text', minimum: 5, minstrictly: true)
    expect(q.minimum).to be_nil
    expect(q.minstrictly).to be_nil
  end
end
